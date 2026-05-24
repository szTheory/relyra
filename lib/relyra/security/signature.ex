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

  Phase 21 contract per D-16: this MUST be called BEFORE the candidate is
  parsed deeply (no `Parser.parse` invocation between fetch and this call
  on the scheduled path). The caller (Phase 21 wrapper) builds a
  metadata-root-shaped `parsed_doc` map exposing the `:signed_candidates`
  rooted at the EntityDescriptor / EntitiesDescriptor envelope.

  `cert_chain` MUST be the operator-pinned PEM list resolved from
  `MetadataSource.metadata_trust_fingerprints` per D-17 — NEVER the IdP's
  assertion certs.
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

    with :ok <-
           evaluate_policy(
             AlgorithmPolicy.enforce_signature_method(policy, signature_method),
             details
           ),
         :ok <-
           evaluate_policy(AlgorithmPolicy.enforce_digest_method(policy, digest_method), details) do
      verified_signed_node(parsed_doc, signature_method, digest_method, cert_chain, details)
    end
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
        # D-01: THE published-hex auth-bypass site. The crypto runs BETWEEN
        # matching the single [candidate] and building %SignedNode{}. All
        # pre-existing trust gates already ran in do_verify/4 (cert_chain present,
        # KeyInfo-trust rejection, duplicate-ID, algorithm allowlist) and the
        # single-candidate selection happened above — none of that is touched.
        # `candidate` is the RAW enriched map off parsed_doc[:signed_candidates]
        # (Plan 02 D-02), NOT a select_candidate handle.
        with :ok <-
               cryptographically_verify(candidate, signature_method, cert_chain, details) do
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

  # Real cryptographic XMLDSig verification of the bound candidate (D-01..D-08).
  # Every step fails CLOSED to a typed %Relyra.Error{} naming the failed check;
  # NOTHING here may raise (Pitfalls 3, 4). Step order matters: the digest-atom
  # / ECDSA gate (D-06/D-07) runs BEFORE any verify attempt, then key extraction
  # (D-04), then the SignedInfo signature math (D-03), then the Reference digest
  # recompute (D-05). %SignedNode{} is only built when BOTH crypto checks pass.
  defp cryptographically_verify(candidate, signature_method, cert_chain, details) do
    signed_info_node = Map.get(candidate, :signed_info_node)
    signature_value_b64 = Map.get(candidate, :signature_value_b64)
    digest_value_b64 = Map.get(candidate, :digest_value_b64)
    referenced_node = Map.get(candidate, :node)

    with :ok <- require_field(signed_info_node, :missing_signature, "SignedInfo", details),
         :ok <-
           require_field(signature_value_b64, :invalid_signature, "SignatureValue", details),
         :ok <- require_field(digest_value_b64, :digest_mismatch, "DigestValue", details),
         :ok <- require_field(referenced_node, :missing_signature, "referenced node", details),
         # 1. Digest-atom + ECDSA gate (D-06/D-07) — fail CLOSED before any verify.
         {:ok, digest_atom} <- digest_atom(signature_method, details),
         # 2. Trust-source public key (D-04) — configured cert_chain only.
         {:ok, public_key} <- public_key_from_cert_chain(cert_chain, details),
         # 3. Signature math (D-03) — :public_key.verify of the canonical SignedInfo.
         :ok <-
           verify_signature_math(
             signed_info_node,
             signature_value_b64,
             digest_atom,
             public_key,
             details
           ),
         # 4. Digest check (D-05) — recompute over the canonical referenced element.
         :ok <- verify_reference_digest(candidate, digest_value_b64, digest_atom, details) do
      :ok
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

  # D-06/D-07: map the signature-method URI to the digest atom, failing CLOSED
  # for ECDSA / unknown (the typed reject is the contract — the allowlist still
  # permits ECDSA URIs, Plan 02 decision).
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

  # D-04: extract the RSA public key from the FIRST (leaf) configured cert PEM.
  # Mirrors the certificate_facts.ex:26-47 pem_decode + try/rescue idiom and
  # fails CLOSED with :untrusted_certificate on ANY malformed PEM/DER (Pitfall 3
  # — pem_entry_decode / pkix_decode_cert RAISE on malformed input). Per A1 the
  # configured signing cert is the single/first entry; chain-walk is out of scope.
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

  # D-03: canonicalize the SignedInfo (bare exclusive-C14N — SignedInfo carries
  # NO enveloped-signature transform; reading its own ds:CanonicalizationMethod
  # InclusiveNamespaces PrefixList when present, empty list otherwise) and verify
  # the decoded SignatureValue with :public_key.verify against the configured key.
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

  # D-05: recompute the Reference digest over the canonicalized, transformed
  # referenced element (PureBeam.canonicalize over the bound :node — the EXACT
  # node the verifier consumes, anti-XSW) and constant-time-compare it to the
  # declared DigestValue. Length-guard BEFORE :crypto.hash_equals/2 (Pitfall 4 —
  # it RAISES on unequal-length inputs).
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
  # which scans a node for an InclusiveNamespaces descendant). Empty list is the
  # DERIVED result for the local signer (Open Q2), NOT a hardcoded default.
  defp signed_info_prefix_list(signed_info_node) do
    C14N.prefix_list_from_transforms(signed_info_node)
  end

  defp decode_b64(value) when is_binary(value), do: Base.decode64(value)
  defp decode_b64(_value), do: :error

  # :public_key.verify/4 returns false on a bad signature (no raise) but RAISES
  # on a malformed KEY / decoded ASN.1 (Pitfall 3). Wrap it so a malformed key
  # surfaces as a non-verifying result (the caller emits :invalid_signature),
  # never an escaping exception on the auth path.
  defp safe_verify(message, digest_atom, signature, public_key) do
    :public_key.verify(message, digest_atom, signature, public_key)
  rescue
    _ -> false
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
