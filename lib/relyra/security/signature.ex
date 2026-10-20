defmodule Relyra.Security.Signature do
  @moduledoc false

  alias Relyra.Error
  alias Relyra.Security.AlgorithmPolicy
  alias Relyra.Security.SignedNode
  alias Relyra.Security.XML.C14N
  alias Relyra.Security.XML.PureBeam

  @spec verify(map(), map(), [binary()], keyword()) :: {:ok, SignedNode.t()} | {:error, Error.t()}
  def verify(parsed_doc, connection, cert_chain, opts \\ [])

  def verify(parsed_doc, connection, cert_chain, opts)
      when is_map(parsed_doc) and is_map(connection) and is_list(cert_chain) and is_list(opts) do
    metadata = %{
      connection_id: Map.get(connection, :connection_id) || Map.get(connection, :id),
      flow: :sp_initiated
    }

    Relyra.Telemetry.span([:signature, :verify], metadata, fn ->
      result = do_verify(parsed_doc, connection, cert_chain, opts)

      case result do
        {:ok, signed_node} ->
          {{:ok, signed_node},
           Map.merge(metadata, %{
             outcome: :ok,
             signature_algorithm: signed_node.signature_method,
             digest_algorithm: signed_node.digest_method
           })}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  def verify(_parsed_doc, connection, _cert_chain, _opts) do
    details = connection_details(connection)

    {:error,
     Error.new(
       :invalid_signature,
       "Signature verification inputs are invalid",
       Map.put(details, :reason, :invalid_signature_input)
     )}
  end

  @doc """
  Verifies the XMLDSig signature on a SAML metadata root (`<EntityDescriptor>`
  or `<EntitiesDescriptor>`) using the SAME `do_verify/4` trust primitive
  `verify/4` uses. The only difference is the telemetry payload's `:flow`
  tag (`:metadata_refresh` instead of `:sp_initiated`) so adopters can
  attach distinct handlers to the unattended metadata-refresh channel.

  Verify the metadata root signature before the candidate is parsed deeply.
  `cert_chain` must contain the operator-pinned PEM certificates resolved from
  `MetadataSource.metadata_trust_fingerprints`; never use the IdP assertion
  certificates as metadata trust anchors.
  """
  @spec verify_metadata_root(map(), map(), [binary()], keyword()) ::
          {:ok, SignedNode.t()} | {:error, Error.t()}
  def verify_metadata_root(parsed_doc, connection, cert_chain, opts \\ [])

  def verify_metadata_root(parsed_doc, connection, cert_chain, opts)
      when is_map(parsed_doc) and is_map(connection) and is_list(cert_chain) and is_list(opts) do
    metadata = %{
      connection_id: Map.get(connection, :connection_id) || Map.get(connection, :id),
      flow: :metadata_refresh
    }

    Relyra.Telemetry.span([:signature, :verify], metadata, fn ->
      result = do_verify(parsed_doc, connection, cert_chain, opts)

      case result do
        {:ok, signed_node} ->
          {{:ok, signed_node},
           Map.merge(metadata, %{
             outcome: :ok,
             signature_algorithm: signed_node.signature_method,
             digest_algorithm: signed_node.digest_method
           })}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  def verify_metadata_root(_parsed_doc, connection, _cert_chain, _opts) do
    details = connection_details(connection)

    {:error,
     Error.new(
       :invalid_signature,
       "Metadata-root signature verification inputs are invalid",
       Map.put(details, :reason, :invalid_signature_input)
     )}
  end

  @doc """
  Sign the pre-assembled HTTP-Redirect-binding query-string binary and return
  the URL-encoded base64 Signature value to append.

  `octets` must be the exact wire bytes before `&Signature=` is appended. This
  function signs those bytes verbatim and MUST NOT re-encode the query.
  """
  @spec sign_redirect_query(binary(), String.t(), keyword()) ::
          {:ok, binary()} | {:error, Error.t()}
  def sign_redirect_query(octets, signature_method, opts \\ [])

  def sign_redirect_query(octets, signature_method, opts)
      when is_binary(octets) and octets != "" and is_binary(signature_method) and is_list(opts) do
    details = %{signature_method: signature_method}

    with {:ok, digest_atom} <- signing_digest_atom(signature_method, details),
         {:ok, private_key} <- load_signing_key(opts, details),
         {:ok, sig_bytes} <- safe_sign(octets, digest_atom, private_key) do
      {:ok, sig_bytes |> Base.encode64() |> URI.encode_www_form()}
    end
  end

  def sign_redirect_query(_octets, signature_method, _opts) do
    {:error,
     Error.new(
       :invalid_signature,
       "Redirect signing inputs are invalid",
       %{signature_method: signature_method, reason: :invalid_signature_input}
     )}
  end

  @doc """
  Verifies an HTTP-Redirect binding signature mathematically.

  `raw_query_string` MUST be the exact octets of the query parameters
  before the `&Signature=...` parameter (e.g. `SAMLRequest=...&RelayState=...&SigAlg=...`).
  This function does NOT decode or manipulate the string.
  """
  @spec verify_redirect_signature(binary(), atom(), binary(), term()) ::
          :ok | {:error, Error.t()}
  def verify_redirect_signature(raw_query_string, digest_atom, signature_bytes, public_key)
      when is_binary(raw_query_string) and is_atom(digest_atom) and is_binary(signature_bytes) do
    if safe_verify(raw_query_string, digest_atom, signature_bytes, public_key) do
      :ok
    else
      {:error,
       Error.new(:invalid_signature, "Redirect signature failed cryptographic verification", %{
         reason: :redirect_signature_mismatch
       })}
    end
  end

  def verify_redirect_signature(_raw_query_string, _digest_atom, _signature_bytes, _public_key) do
    {:error,
     Error.new(:invalid_signature, "Invalid inputs to redirect signature verification", %{
       reason: :invalid_signature_input
     })}
  end

  defp do_verify(parsed_doc, connection, cert_chain, opts) do
    details = connection_details(connection)
    duplicate_xml_ids = Map.get(parsed_doc, :duplicate_ids) || []

    cond do
      cert_chain == [] ->
        {:error,
         Error.new(:untrusted_certificate, "Configured certificate chain is required", details)}

      Map.get(parsed_doc, :key_info_trust) == true ->
        {:error,
         Error.new(
           :untrusted_certificate,
           "Document-provided KeyInfo cannot be used as a trust source",
           Map.put(details, :reason, :document_keyinfo_forbidden)
         )}

      duplicate_xml_ids != [] ->
        {:error,
         Error.new(
           :duplicate_xml_id,
           "Duplicate XML IDs detected in signed material",
           Map.merge(details, %{
             duplicate_ids: duplicate_xml_ids,
             duplicate_count: length(duplicate_xml_ids)
           })
         )}

      true ->
        verify_algorithms_and_candidates(parsed_doc, details, cert_chain, opts)
    end
  end

  defp verify_algorithms_and_candidates(parsed_doc, details, cert_chain, opts) do
    policy = Keyword.get(opts, :algorithm_policy, AlgorithmPolicy.default())
    signature_method = Map.get(parsed_doc, :signature_method)
    digest_method = Map.get(parsed_doc, :digest_method)

    canonicalization_method = Map.get(parsed_doc, :canonicalization_method)

    with :ok <-
           evaluate_policy(
             AlgorithmPolicy.enforce_signature_method(policy, signature_method),
             details
           ),
         :ok <-
           evaluate_policy(AlgorithmPolicy.enforce_digest_method(policy, digest_method), details),
         :ok <- enforce_canonicalization_method(canonicalization_method, details) do
      verified_signed_node(parsed_doc, signature_method, digest_method, cert_chain, details)
    end
  end

  # A DECLARED ds:CanonicalizationMethod must be Exclusive C14N 1.0 — the one
  # algorithm the C14N engine byte-proves (S4). An absent declaration is not
  # rejected here: the SignedInfo is always canonicalized with Exclusive C14N, so
  # a signature produced under any other algorithm already fails the signature
  # math. An explicit non-exc-c14n declaration is rejected as defense in depth.
  defp enforce_canonicalization_method(nil, _details), do: :ok

  defp enforce_canonicalization_method("http://www.w3.org/2001/10/xml-exc-c14n#", _details),
    do: :ok

  defp enforce_canonicalization_method(method, details) do
    {:error,
     Error.new(
       :unsupported_canonicalization_method,
       "SignedInfo CanonicalizationMethod is not the supported Exclusive C14N algorithm",
       Map.put(details, :canonicalization_method, method)
     )}
  end

  defp evaluate_policy(:ok, _details), do: :ok

  defp evaluate_policy(%Error{} = error, details) do
    {:error, merge_error_details(error, details)}
  end

  defp verified_signed_node(parsed_doc, signature_method, digest_method, cert_chain, details) do
    signed_candidates = Map.get(parsed_doc, :signed_candidates, [])

    case signed_candidates do
      [] ->
        {:error,
         Error.new(:missing_signature, "No signed node candidates were verified", details)}

      [candidate] ->
        # Verify the selected candidate before constructing SignedNode. The
        # candidate retains the parsed document's signed node, SignedInfo, and
        # Reference binding used by the cryptographic checks below.
        with :ok <-
               cryptographically_verify(
                 candidate,
                 signature_method,
                 digest_method,
                 cert_chain,
                 details
               ) do
          {:ok,
           %SignedNode{
             xml_id: Map.get(candidate, :xml_id),
             xpath: Map.get(candidate, :xpath),
             signed_xml: Map.get(candidate, :signed_xml, ""),
             signature_method: signature_method,
             digest_method: digest_method
           }}
        end

      candidates ->
        {:error,
         Error.new(
           :ambiguous_signed_node,
           "Exactly one verified signed node is required",
           Map.merge(details, %{candidate_count: length(candidates)})
         )}
    end
  end

  # Fail closed with a typed error for invalid inputs, unsupported verification
  # methods, an unusable configured key, a bad SignedInfo signature, or a
  # mismatched Reference digest. Construct SignedNode only after both
  # cryptographic checks succeed.
  defp cryptographically_verify(candidate, signature_method, digest_method, cert_chain, details) do
    signed_info_node = Map.get(candidate, :signed_info_node)
    signature_value_b64 = Map.get(candidate, :signature_value_b64)
    digest_value_b64 = Map.get(candidate, :digest_value_b64)
    referenced_node = Map.get(candidate, :node)

    with :ok <- require_field(signed_info_node, :missing_signature, "SignedInfo", details),
         :ok <-
           require_field(signature_value_b64, :invalid_signature, "SignatureValue", details),
         :ok <- require_field(digest_value_b64, :digest_mismatch, "DigestValue", details),
         :ok <- require_field(referenced_node, :missing_signature, "referenced node", details),
         # The SignedInfo signature hash comes from the SignatureMethod; the
         # Reference digest hash comes from the bound DigestMethod (S4). They are
         # resolved independently so a mismatched pair cannot reuse one atom.
         {:ok, signature_digest_atom} <- digest_atom(signature_method, details),
         {:ok, reference_digest_atom} <- reference_digest_atom(digest_method, details),
         # Derive the verification key only from configured certificates.
         {:ok, public_key} <- public_key_from_cert_chain(cert_chain, details),
         # Verify the canonical SignedInfo with the configured certificate key.
         :ok <-
           verify_signature_math(
             signed_info_node,
             signature_value_b64,
             signature_digest_atom,
             public_key,
             details
           ),
         # Recompute the digest over the canonicalized referenced node.
         :ok <-
           verify_reference_digest(candidate, digest_value_b64, reference_digest_atom, details) do
      :ok
    end
  end

  # Map the bound ds:DigestMethod URI to the digest atom used to recompute the
  # Reference digest. ECDSA has no bearing here; any unsupported or absent URI
  # fails closed.
  defp reference_digest_atom(digest_method, details) do
    case digest_method do
      "http://www.w3.org/2001/04/xmlenc#sha256" ->
        {:ok, :sha256}

      "http://www.w3.org/2001/04/xmldsig-more#sha384" ->
        {:ok, :sha384}

      "http://www.w3.org/2001/04/xmlenc#sha512" ->
        {:ok, :sha512}

      _ ->
        {:error,
         Error.new(
           :digest_mismatch,
           "DigestMethod is not a supported digest algorithm",
           Map.put(details, :digest_method, digest_method)
         )}
    end
  end

  defp require_field(value, _error_type, _label, _details) when not is_nil(value), do: :ok

  defp require_field(_value, error_type, label, details) do
    {:error,
     Error.new(
       error_type,
       "Signed candidate is missing required #{label}",
       Map.put(details, :reason, :missing_signature_input)
     )}
  end

  # Map the signature method to the digest used for cryptographic verification.
  # Reject methods without a supported verification digest, even if the
  # configured algorithm policy recognizes their URI.
  defp digest_atom(signature_method, details) do
    case AlgorithmPolicy.digest_atom_for_signature_method(signature_method) do
      {:ok, atom} ->
        {:ok, atom}

      {:error, :unsupported_signature_algorithm} ->
        {:error,
         Error.new(
           :unsupported_signature_algorithm,
           "Signature algorithm is not supported for cryptographic verification",
           Map.put(details, :signature_method, signature_method)
         )}
    end
  end

  # Extract the public key from the first configured certificate and fail
  # closed with :untrusted_certificate if its PEM or DER cannot be decoded.
  defp public_key_from_cert_chain(cert_chain, details) do
    case public_key_from_cert_chain(cert_chain) do
      {:ok, public_key} ->
        {:ok, public_key}

      {:error, :untrusted_certificate} ->
        {:error,
         Error.new(
           :untrusted_certificate,
           "Configured certificate public key could not be extracted",
           Map.put(details, :reason, :public_key_extraction_failed)
         )}
    end
  end

  @doc false
  # Bare PEM→public-key extraction (no %Relyra.Error{} wrapping). Returns
  # {:ok, public_key} | {:error, :untrusted_certificate}. NEVER raises.
  def public_key_from_cert_chain([pem | _rest]) when is_binary(pem) do
    with [entry | _] <- :public_key.pem_decode(pem),
         der when is_binary(der) <- elem(entry, 1) do
      {:OTPCertificate, otp_tbs, _sig_alg, _sig} = :public_key.pkix_decode_cert(der, :otp)
      {:OTPSubjectPublicKeyInfo, _alg_id, public_key} = :erlang.element(8, otp_tbs)
      {:ok, public_key}
    else
      _ -> {:error, :untrusted_certificate}
    end
  rescue
    _ -> {:error, :untrusted_certificate}
  end

  def public_key_from_cert_chain(_cert_chain), do: {:error, :untrusted_certificate}

  defp signing_digest_atom(signature_method, details) do
    case AlgorithmPolicy.signing_digest_atom(signature_method) do
      {:ok, atom} ->
        {:ok, atom}

      {:error, error_type} ->
        {:error,
         Error.new(
           error_type,
           "Signing algorithm is not supported for outbound redirect signing",
           Map.put(details, :signature_method, signature_method)
         )}
    end
  end

  defp load_signing_key(opts, details) do
    signing_key_pem =
      Keyword.get(opts, :signing_key_pem) ||
        Application.get_env(:relyra, :sp_signing_key_pem)

    with pem when is_binary(pem) <- signing_key_pem,
         [entry | _] <- :public_key.pem_decode(pem),
         private_key <- :public_key.pem_entry_decode(entry) do
      {:ok, private_key}
    else
      _ ->
        {:error,
         Error.new(
           :key_not_configured,
           "SP signing key is not configured",
           Map.put(
             details,
             :hint,
             "Set config :relyra, :sp_signing_key_pem to the PEM binary of the SP RSA private key"
           )
         )}
    end
  rescue
    _ ->
      {:error,
       Error.new(
         :key_not_configured,
         "SP signing key is not configured",
         Map.put(
           details,
           :hint,
           "Set config :relyra, :sp_signing_key_pem to the PEM binary of the SP RSA private key"
         )
       )}
  end

  # Canonicalize SignedInfo using its declared canonicalization parameters, then
  # verify SignatureValue with :public_key.verify and the configured certificate
  # key.
  defp verify_signature_math(
         signed_info_node,
         signature_value_b64,
         digest_atom,
         public_key,
         details
       ) do
    prefix_list = signed_info_prefix_list(signed_info_node)

    with {:ok, c14n_signed_info} <- C14N.serialize(signed_info_node, prefix_list: prefix_list),
         {:ok, sig_bytes} <- decode_b64(signature_value_b64) do
      if safe_verify(c14n_signed_info, digest_atom, sig_bytes, public_key) do
        :ok
      else
        {:error,
         Error.new(
           :invalid_signature,
           "SignatureValue failed cryptographic verification",
           details
         )}
      end
    else
      :error ->
        {:error,
         Error.new(
           :invalid_signature,
           "SignatureValue is not valid base64",
           details
         )}

      {:error, %Error{} = error} ->
        {:error, merge_error_details(error, details)}
    end
  end

  # Recompute the Reference digest over the canonicalized node bound to this
  # candidate, then compare it with DigestValue in constant time. Check lengths
  # first because :crypto.hash_equals/2 requires equal-length binaries.
  defp verify_reference_digest(candidate, digest_value_b64, digest_atom, details) do
    with {:ok, %{canonical_xml: ref_bytes}} <- PureBeam.canonicalize(candidate),
         {:ok, declared} <- decode_b64(digest_value_b64) do
      recomputed = :crypto.hash(digest_atom, ref_bytes)

      if byte_size(recomputed) == byte_size(declared) and
           :crypto.hash_equals(recomputed, declared) do
        :ok
      else
        {:error,
         Error.new(
           :digest_mismatch,
           "Recomputed Reference digest does not match DigestValue",
           details
         )}
      end
    else
      :error ->
        {:error,
         Error.new(
           :digest_mismatch,
           "DigestValue is not valid base64",
           details
         )}

      {:error, %Error{} = error} ->
        {:error, merge_error_details(error, details)}
    end
  end

  # Read the SignedInfo's own ds:CanonicalizationMethod InclusiveNamespaces
  # PrefixList when present (reusing the C14N.prefix_list_from_transforms/1 shape,
  # which scans a node for an InclusiveNamespaces descendant). An absent list
  # produces an empty list from the canonicalization parameters.
  defp signed_info_prefix_list(signed_info_node) do
    C14N.prefix_list_from_transforms(signed_info_node)
  end

  # Tolerate internal whitespace: real IdPs (ADFS, Shibboleth, OpenSAML stacks)
  # line-wrap <ds:SignatureValue>/<ds:DigestValue> base64 at 64/76 columns
  # Without `ignore: :whitespace`, Base.decode64/1 rejects embedded
  # newlines, yielding spurious :invalid_signature / :digest_mismatch on
  # legitimately signed material.
  defp decode_b64(value) when is_binary(value), do: Base.decode64(value, ignore: :whitespace)
  defp decode_b64(_value), do: :error

  # Treat verification errors from malformed keys as a failed signature so an
  # exception never escapes the authentication path.
  defp safe_verify(message, digest_atom, signature, public_key) do
    :public_key.verify(message, digest_atom, signature, public_key)
  rescue
    _ -> false
  end

  defp safe_sign(message, digest_atom, private_key) do
    {:ok, :public_key.sign(message, digest_atom, private_key)}
  rescue
    _ ->
      {:error,
       Error.new(
         :key_not_configured,
         "SP signing key could not produce a redirect signature",
         %{reason: :private_key_sign_failed}
       )}
  end

  defp merge_error_details(%Error{details: error_details} = error, details)
       when is_map(error_details) do
    %{error | details: Map.merge(details, error_details)}
  end

  defp merge_error_details(%Error{} = error, details), do: %{error | details: details}

  defp connection_details(connection) when is_map(connection) do
    connection_id =
      Map.get(connection, :connection_id) ||
        Map.get(connection, "connection_id") ||
        Map.get(connection, :id) ||
        Map.get(connection, "id")

    %{connection_id: connection_id}
  end

  defp connection_details(_connection), do: %{connection_id: nil}
end
