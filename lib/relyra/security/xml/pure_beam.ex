defmodule Relyra.Security.XML.PureBeam do
  @moduledoc """
  Pure-BEAM baseline adapter for XML seam enforcement.

  Phase 28 (D-04): a single hardened parser path. `parse_safely/2` runs the
  pre-parse byte guards (DOCTYPE / ENTITY / size) on the raw binary BEFORE any
  parse (XXE-before-verify invariant, D-09), then routes the well-formed arm to
  `Relyra.Security.XML.SaxyTree` and re-derives EVERY downstream protocol field
  from the resulting parse tree in one pass — the regex extractors are retired so
  no parser/canonicalization differential exists (D-04, threat T-28-11).

  The flat `parsed_doc` key contract is preserved additively (D-08): every legacy
  key downstream readers (`Relyra.Security.Signature`,
  `Relyra.Protocol.ValidationPipeline`) consume is reproduced, and the parse tree
  is attached as a NEW `:parse_tree` key. The selected handle binds the EXACT
  tree node `canonicalize/2` serializes (D-10, anti-XSW), and `canonicalize/2`
  delegates to the `Relyra.Security.XML.C14N` exclusive-C14N engine on that node
  while failing closed (`:canonicalization_failed`) for any non-bindable handle
  (Pitfall 9, threat T-28-12).
  """

  @behaviour Relyra.Security.XML

  alias Relyra.Error
  alias Relyra.Security.XML.C14N
  alias Relyra.Security.XML.SaxyTree
  alias Relyra.Security.XML.SaxyTree.Node

  @default_opts [max_bytes: 1_048_576]

  # The enveloped-signature transform URI (XMLDSig §6.6.4). Used only to guard
  # the canonicalize/2 fail-closed path: if a Reference requests it but the bound
  # ds:Signature node is unresolved, refuse rather than serialize-without-pruning.
  @enveloped_signature "http://www.w3.org/2000/09/xmldsig#enveloped-signature"

  # Namespace URIs used for structural, namespace-aware binding (Phase 80, S20).
  # A security element matches only when its resolved namespace URI is one of
  # these, or when it carries no namespace at all.
  @saml_assertion_ns "urn:oasis:names:tc:SAML:2.0:assertion"
  @samlp_ns "urn:oasis:names:tc:SAML:2.0:protocol"
  @dsig_ns "http://www.w3.org/2000/09/xmldsig#"
  @bearer_method "urn:oasis:names:tc:SAML:2.0:cm:bearer"

  @impl true
  def parse_safely(xml, opts \\ [])

  def parse_safely(xml, opts) when is_binary(xml) do
    max_bytes = Keyword.get(Keyword.merge(@default_opts, opts), :max_bytes)

    cond do
      byte_size(xml) > max_bytes ->
        {:error,
         Error.new(:payload_too_large, "XML payload exceeds max_bytes limit", %{
           max_bytes: max_bytes
         })}

      String.contains?(xml, "<!DOCTYPE") ->
        {:error, Error.new(:doctype_forbidden, "DOCTYPE declarations are forbidden")}

      String.contains?(xml, "<!ENTITY") ->
        {:error, Error.new(:entity_expansion_forbidden, "ENTITY declarations are forbidden")}

      true ->
        parse_tree(xml)
    end
  end

  def parse_safely(_xml, _opts), do: malformed_xml_error()

  @doc """
  Pre-parse a SAML metadata document and produce a metadata-root-shaped
  `parsed_doc` for the signed-metadata trust path (SIGV-04, D-13).

  This is the metadata sibling of `parse_safely/2`: it runs the SAME pre-parse
  byte guards (DOCTYPE / ENTITY / size) on the raw binary BEFORE any parse
  (XXE-before-verify, D-09), routes the well-formed arm to the SAME `SaxyTree`
  parser (D-04, one trust path — no regex, no second parser), and emits the SAME
  canonical signed-candidate shape `signed_candidates/1` emits (carrying the
  D-02 crypto inputs `:signed_info_node` / `:digest_value_b64` /
  `:signature_value_b64` plus the bound `:node`), but rooted at the metadata
  envelope (`<EntityDescriptor>` / `<EntitiesDescriptor>`) instead of an
  `<Assertion>`.

  Returns `{:ok, parsed_doc}` whose single `:signed_candidates` entry binds the
  EXACT metadata-root tree node `canonicalize/2` serializes (anti-XSW), plus
  `:signature_method` / `:digest_method` (from the SignedInfo), `:key_info_trust`
  and `:duplicate_ids` (tree-derived) so the shared `do_verify/4` gates inherit
  to the metadata path. Returns `{:error, %Error{type: :missing_signature}}` when
  no signed `<EntityDescriptor>` / `<EntitiesDescriptor>` root is present (fail
  closed), or the same byte-guard / `:malformed_xml` errors `parse_safely/2`
  returns.
  """
  @spec parse_metadata_root_safely(binary(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def parse_metadata_root_safely(xml, opts \\ [])

  def parse_metadata_root_safely(xml, opts) when is_binary(xml) do
    max_bytes = Keyword.get(Keyword.merge(@default_opts, opts), :max_bytes)

    cond do
      byte_size(xml) > max_bytes ->
        {:error,
         Error.new(:payload_too_large, "XML payload exceeds max_bytes limit", %{
           max_bytes: max_bytes
         })}

      String.contains?(xml, "<!DOCTYPE") ->
        {:error, Error.new(:doctype_forbidden, "DOCTYPE declarations are forbidden")}

      String.contains?(xml, "<!ENTITY") ->
        {:error, Error.new(:entity_expansion_forbidden, "ENTITY declarations are forbidden")}

      true ->
        parse_metadata_tree(xml)
    end
  end

  def parse_metadata_root_safely(_xml, _opts), do: malformed_xml_error()

  # Route the well-formed arm to the saxy tree builder, then derive the flat
  # parsed_doc from the tree. The pre-parse byte guards above already ran on the
  # raw binary, so no DTD / entity / oversize payload reaches Saxy.
  defp parse_tree(xml) do
    case SaxyTree.parse(xml) do
      {:ok, %Node{} = root} ->
        build_parsed_doc(root)

      {:error, %Saxy.ParseError{} = error} ->
        {:error,
         Error.new(:malformed_xml, "Malformed XML payload", %{
           reason: Saxy.ParseError.message(error)
         })}
    end
  end

  # The metadata sibling of parse_tree/1: parse with the SAME SaxyTree engine,
  # then locate the signed metadata-root envelope and derive the metadata-root
  # parsed_doc. No regex, no second parser (D-04).
  defp parse_metadata_tree(xml) do
    case SaxyTree.parse(xml) do
      {:ok, %Node{} = root} ->
        build_metadata_parsed_doc(root)

      {:error, %Saxy.ParseError{} = error} ->
        {:error,
         Error.new(:malformed_xml, "Malformed XML payload", %{
           reason: Saxy.ParseError.message(error)
         })}
    end
  end

  # Find the signed metadata-root envelope (the EntityDescriptor /
  # EntitiesDescriptor that carries a child ds:Signature) and emit the canonical
  # metadata-root parsed_doc. Fails closed (:missing_signature) when no such
  # signed root is present — the metadata-path analogue of the assertion path's
  # :missing_signature fail-closed.
  defp build_metadata_parsed_doc(%Node{} = root) do
    case signed_metadata_root(root) do
      %Node{} = metadata_root ->
        signature_node = direct_child(metadata_root, "Signature")
        signed_info_node = maybe_find(signature_node, "SignedInfo")

        signature_method = first_attr_in(signed_info_node, "SignatureMethod", "Algorithm")
        digest_method = first_attr_in(signed_info_node, "DigestMethod", "Algorithm")

        {:ok,
         %{
           type: :parsed_metadata_xml,
           parse_tree: root,
           signature_method: signature_method,
           digest_method: digest_method,
           signed_candidates: [
             metadata_root_candidate(
               metadata_root,
               signature_node,
               signed_info_node,
               signature_method,
               digest_method
             )
           ],
           # Tree-derived so the shared do_verify/4 gates (document-KeyInfo
           # rejection, duplicate-ID rejection) inherit to the metadata path
           # (T-29-22). KeyInfo trust is scoped to the bound ds:Signature's OWN
           # KeyInfo — the signature's self-asserted key (which MUST be rejected;
           # the operator pins the trust anchor out-of-band, never the document's
           # signature KeyInfo). A KeyDescriptor/KeyInfo elsewhere in the
           # metadata is the legitimately PUBLISHED signing cert (gated by
           # TrustAnchor pinning), NOT a document-trust bypass — so it is NOT
           # flagged here. On the assertion path the only KeyInfo is the
           # signature's, so this is the faithful semantic analogue.
           key_info_trust: element_present?(signature_node, "KeyInfo"),
           duplicate_ids: duplicate_ids(root)
         }}

      nil ->
        {:error,
         Error.new(
           :missing_signature,
           "Metadata XML has no <EntityDescriptor> or <EntitiesDescriptor> root with a child <ds:Signature>",
           %{}
         )}
    end
  end

  # The first EntityDescriptor / EntitiesDescriptor (document order,
  # descendant-or-self) that carries a DIRECT-child ds:Signature — the signed
  # metadata envelope. The signature must be a direct child (not buried inside a
  # KeyDescriptor) so the bound node is the EXACT envelope the signature covers.
  defp signed_metadata_root(%Node{} = root) do
    [find_first(root, "EntityDescriptor"), find_first(root, "EntitiesDescriptor")]
    |> Enum.find(fn
      %Node{} = node -> is_struct(direct_child(node, "Signature"), Node)
      _ -> false
    end)
  end

  # The metadata-root candidate in the SAME canonical shape signed_candidates/1
  # emits (D-02 crypto inputs + the bound :node), rooted at the metadata
  # envelope. :node is bound to the EXACT EntityDescriptor / EntitiesDescriptor
  # tree node canonicalize/2 serializes (anti-XSW) and transforms_node is read
  # off the bound ds:Signature (mirroring the assertion path).
  defp metadata_root_candidate(
         %Node{} = metadata_root,
         signature_node,
         signed_info_node,
         signature_method,
         digest_method
       ) do
    transforms_node = maybe_find(signature_node, "Transforms")

    %{
      xml_id: attr(metadata_root, "ID"),
      xpath: "/" <> metadata_root.local,
      signed_xml: render_signed_xml(metadata_root),
      node: metadata_root,
      signature_node: signature_node,
      transforms_node: transforms_node,
      signed_info_node: signed_info_node,
      digest_value_b64: trimmed_node_text(maybe_find(signature_node, "DigestValue")),
      signature_value_b64: trimmed_node_text(maybe_find(signature_node, "SignatureValue")),
      signature_method: signature_method,
      digest_method: digest_method
    }
  end

  # Single-pass derivation of every legacy parsed_doc key from the tree (D-04),
  # plus the additive :parse_tree key (D-07 / D-08). Required-field gates reuse
  # require_present_fields/4 so the :missing_protocol_field / :missing_signature
  # error shapes stay byte-identical to the regex era.
  defp build_parsed_doc(%Node{local: "LogoutRequest"} = root) do
    build_logout_parsed_doc(root)
  end

  defp build_parsed_doc(%Node{local: "LogoutResponse"} = root) do
    build_logout_parsed_doc(root)
  end

  defp build_parsed_doc(%Node{} = root) do
    # ENC-01 (D-01): a Response whose ONLY assertion is encrypted carries no
    # cleartext <Assertion> / <Signature>, so the strict assertion/signature gates
    # below would reject it BEFORE the ValidationPipeline :decrypt_assertion
    # pre-stage can decrypt and re-parse. Emit a minimal pre-decrypt parsed_doc
    # (response_fields + the :parse_tree the pre-stage detects on) WITHOUT relaxing
    # any gate for the cleartext path — the strict gates re-run on the re-parsed
    # decrypted plaintext (one parse path, CLAUDE.md #2). A cleartext+encrypted
    # ambiguity still hits the full cleartext path here (cleartext Assertion present)
    # and is rejected by the pre-stage as :ambiguous_assertion.
    with :ok <- require_response_root(root) do
      # Any <EncryptedAssertion> (with or without a sibling cleartext assertion)
      # routes to the minimal pre-decrypt doc, so the ValidationPipeline decrypt
      # pre-stage can decrypt the single-encrypted case or reject the
      # cleartext+encrypted ambiguity (:ambiguous_assertion) before the strict
      # cleartext binding runs. A document with no EncryptedAssertion takes the
      # strict cleartext binding path directly.
      if has_encrypted_assertion?(root) do
        build_pre_decrypt_parsed_doc(root)
      else
        build_cleartext_parsed_doc(root)
      end
    end
  end

  # The document root MUST be a samlp:Response (S11). A non-Response root — or a
  # Response-named root in a foreign namespace — is rejected before any field is
  # derived.
  defp require_response_root(%Node{local: "Response"} = root) do
    if ns_match?(root, "Response", [@samlp_ns]) do
      :ok
    else
      {:error,
       Error.new(
         :unexpected_root_element,
         "Response root element is in an unexpected namespace",
         %{namespace: ns_uri(root)}
       )}
    end
  end

  defp require_response_root(%Node{local: local}) do
    {:error,
     Error.new(
       :unexpected_root_element,
       "SAML Response document root must be <samlp:Response>",
       %{root_element: local}
     )}
  end

  defp build_logout_parsed_doc(%Node{} = root) do
    base = %{
      type: :parsed_logout_xml,
      parse_tree: root
    }

    # Logout signature binding is hardened in Phase 81. For now the logout path
    # keeps its pre-Phase-80 signature derivation (document-wide methods + the
    # Assertion-based candidate), unchanged, so this phase's scope stays on login.
    case legacy_signature_fields(root) do
      {:ok, fields} -> {:ok, Map.merge(base, fields)}
      {:error, _} -> {:ok, base}
    end
  end

  # Pre-Phase-80 signature derivation, retained ONLY for the logout path until
  # Phase 81 rebinds it to the logout root. Do not use for the login path.
  defp legacy_signature_fields(%Node{} = root) do
    signature_method = first_attr(root, "SignatureMethod", "Algorithm")
    digest_method = first_attr(root, "DigestMethod", "Algorithm")

    fields = %{
      signature_method: signature_method,
      digest_method: digest_method,
      signed_candidates:
        legacy_signed_candidates(root)
        |> Enum.map(fn candidate ->
          Map.merge(candidate, %{
            signature_method: signature_method,
            digest_method: digest_method
          })
        end),
      duplicate_ids: duplicate_ids(root),
      key_info_trust: rogue_key_info_present?(root)
    }

    require_present_fields(
      fields,
      [:signature_method, :digest_method, :signed_candidates],
      :missing_signature,
      "Signed XML material is missing required signature fields"
    )
  end

  defp legacy_signed_candidates(%Node{} = root) do
    response_signature = find_first(root, "Signature")

    root
    |> find_all("Assertion")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {%Node{} = assertion, index} ->
      case attr(assertion, "ID") do
        nil ->
          []

        assertion_id ->
          signature_node = find_first(assertion, "Signature") || response_signature
          transforms_node = signature_node && find_first(signature_node, "Transforms")
          signed_info_node = signature_node && find_first(signature_node, "SignedInfo")

          [
            %{
              xml_id: assertion_id,
              xpath: "/Response/Assertion[#{index}]",
              signed_xml: render_signed_xml(assertion),
              node: assertion,
              signature_node: signature_node,
              transforms_node: transforms_node,
              signed_info_node: signed_info_node,
              digest_value_b64: trimmed_node_text(maybe_find(signature_node, "DigestValue")),
              signature_value_b64: trimmed_node_text(maybe_find(signature_node, "SignatureValue"))
            }
          ]
      end
    end)
  end

  # True iff the document carries at least one <EncryptedAssertion> (prefix-
  # agnostic, by local name). The ValidationPipeline decrypt pre-stage then
  # decrypts the single-encrypted case or rejects the cleartext+encrypted
  # ambiguity before any cleartext binding.
  defp has_encrypted_assertion?(%Node{} = root) do
    not is_nil(find_first(root, "EncryptedAssertion"))
  end

  # The minimal pre-decrypt parsed_doc: response_fields (Issuer/Status/Destination
  # ARE present on the outer encrypted Response) + the :parse_tree. No assertion /
  # signature fields are derived — they live inside the still-encrypted blob and are
  # derived from the re-parsed plaintext after the pre-stage decrypts. No identity
  # field is surfaced here (CLAUDE.md #4 / Pitfall 3).
  defp build_pre_decrypt_parsed_doc(%Node{} = root) do
    with {:ok, response_fields} <- response_fields(root) do
      {:ok,
       %{
         type: :parsed_xml,
         encrypted_pending: true,
         parse_tree: root
       }
       |> Map.merge(response_fields)}
    end
  end

  # Bind the single signed <Assertion> FIRST, then derive every assertion and
  # signature field strictly from that bound node — never from a descendant-or-
  # self search over the whole Response (Phase 80, seams S1-S11, S20). Response-
  # envelope fields (Issuer / Status / Destination) are read from the Response
  # root's own direct children; they are inherently outside the assertion
  # signature in standard assertion-signed SAML, so binding them to the signed
  # node is neither possible nor expected.
  defp build_cleartext_parsed_doc(%Node{} = root) do
    with :ok <- reject_duplicate_ids(root),
         :ok <- reject_rogue_key_info(root),
         {:ok, assertion} <- bind_signed_assertion(root),
         {:ok, response_fields} <- response_fields(root),
         {:ok, assertion_fields} <- assertion_fields(assertion),
         {:ok, signature_fields} <- signature_fields(root, assertion) do
      assertion_times = %{
        not_before: Map.fetch!(assertion_fields, :not_before),
        not_on_or_after: Map.fetch!(assertion_fields, :not_on_or_after),
        subject_confirmation_not_on_or_after:
          Map.fetch!(assertion_fields, :subject_confirmation_not_on_or_after)
      }

      {:ok,
       %{
         type: :parsed_xml,
         assertion_times: assertion_times,
         parse_tree: root,
         signed_assertion_node: assertion
       }
       |> Map.merge(response_fields)
       |> Map.merge(assertion_fields)
       |> Map.merge(signature_fields)}
    end
  end

  # Duplicate ID/id attribute values anywhere in the tree are rejected before
  # anything is bound (CVE-2024-45409 / XSW defense). This runs before the
  # single-assertion cardinality check so a duplicated-ID wrapping attack keeps
  # its precise :duplicate_xml_id signal.
  defp reject_duplicate_ids(%Node{} = root) do
    case duplicate_ids(root) do
      [] ->
        :ok

      dups ->
        {:error,
         Error.new(
           :duplicate_xml_id,
           "Duplicate XML IDs detected in signed material",
           %{duplicate_ids: dups, duplicate_count: length(dups)}
         )}
    end
  end

  # A document-provided KeyInfo outside any ds:Signature is an attempt to supply
  # the SP's trust key from the document (CVE-2024-45409 class). It is rejected
  # before any field derivation so the :untrusted_certificate signal is not
  # masked by a downstream field-shape rejection.
  defp reject_rogue_key_info(%Node{} = root) do
    if rogue_key_info_present?(root) do
      {:error,
       Error.new(
         :untrusted_certificate,
         "Document-provided KeyInfo cannot be used as a trust source",
         %{reason: :document_keyinfo_forbidden}
       )}
    else
      :ok
    end
  end

  # Exactly ONE <Assertion> (any namespace, any depth — cardinality over local
  # name) may be present, and the single one MUST be a direct child of the
  # <Response> root in the SAML assertion namespace (or no namespace). More than
  # one is :ambiguous_signed_node (fail closed; also covers an ID-less decoy
  # sibling, S8, and nested Advice assertions, S12). A single assertion that is
  # not a bound direct child is :missing_protocol_field.
  defp bind_signed_assertion(%Node{} = root) do
    case find_all(root, "Assertion") do
      [_single] ->
        case direct_children_ns(root, "Assertion", [@saml_assertion_ns]) do
          [%Node{} = assertion] ->
            {:ok, assertion}

          _ ->
            {:error,
             Error.new(
               :missing_protocol_field,
               "Signed <Assertion> is not a direct child of the <Response> root",
               %{}
             )}
        end

      [] ->
        {:error,
         Error.new(
           :missing_protocol_field,
           "Response payload carries no <Assertion>",
           %{}
         )}

      multiple ->
        {:error,
         Error.new(
           :ambiguous_signed_node,
           "Exactly one <Assertion> is required in a signed Response",
           %{assertion_count: length(multiple)}
         )}
    end
  end

  defp response_fields(%Node{} = root) do
    fields = %{
      issuer: direct_child_text(root, "Issuer"),
      status: status_code_value(root),
      destination: attr(root, "Destination"),
      in_response_to: attr(root, "InResponseTo"),
      connection_id: attr(root, "ConnectionId")
    }

    require_present_fields(
      fields,
      [:issuer, :status, :destination],
      :missing_protocol_field,
      "Required protocol fields are missing from response payload"
    )
  end

  # Only the <Response>'s own direct <Status>/<StatusCode Value> is authoritative
  # (S10): a nested or injected StatusCode elsewhere must never be read.
  defp status_code_value(%Node{} = root) do
    with %Node{} = status <- first_direct_child(root, "Status"),
         %Node{} = status_code <- first_direct_child(status, "StatusCode") do
      attr(status_code, "Value")
    else
      _ -> nil
    end
  end

  # EVERY field below is derived from within the bound <Assertion> subtree, which
  # the signature covers. Subject-confirmation fields are scoped to the bearer
  # SubjectConfirmation (S9); the assertion's own Issuer is surfaced for the
  # issuer-binding check (S10).
  defp assertion_fields(%Node{} = assertion) do
    bearer_scd = bearer_subject_confirmation_data(assertion)
    conditions = first_descendant_ns(assertion, "Conditions")

    fields = %{
      audiences: all_texts(assertion, "Audience"),
      recipient: attr(bearer_scd, "Recipient"),
      not_before: attr(conditions, "NotBefore"),
      not_on_or_after: attr(conditions, "NotOnOrAfter"),
      subject_confirmation_not_on_or_after: attr(bearer_scd, "NotOnOrAfter"),
      subject_confirmation_in_response_to: attr(bearer_scd, "InResponseTo"),
      consumed_xml_id: attr(assertion, "ID"),
      assertion_issuer: assertion_issuer(assertion),
      name_id: subject_name_id_text(assertion),
      name_id_format: subject_name_id_format(assertion),
      session_index: first_attr(assertion, "AuthnStatement", "SessionIndex"),
      attributes: derive_attributes(assertion)
    }

    require_present_fields(
      fields,
      [
        :audiences,
        :recipient,
        :not_before,
        :not_on_or_after,
        :subject_confirmation_not_on_or_after,
        :consumed_xml_id
      ],
      :missing_protocol_field,
      "Required assertion fields are missing from response payload"
    )
  end

  # The Assertion's own direct-child <Issuer> text (S10). An <Issuer> nested
  # deeper (e.g. inside an Advice assertion) is not read.
  defp assertion_issuer(%Node{} = assertion) do
    case first_direct_child(assertion, "Issuer") do
      %Node{} = issuer -> trimmed_text(issuer)
      _ -> nil
    end
  end

  # NameID strictly from the Assertion's Subject (S7), not any descendant NameID.
  defp subject_name_id_text(%Node{} = assertion) do
    case subject_name_id(assertion) do
      %Node{} = name_id -> trimmed_text(name_id)
      _ -> nil
    end
  end

  defp subject_name_id_format(%Node{} = assertion) do
    attr(subject_name_id(assertion), "Format")
  end

  defp subject_name_id(%Node{} = assertion) do
    with %Node{} = subject <- first_direct_child(assertion, "Subject") do
      first_direct_child(subject, "NameID")
    else
      _ -> nil
    end
  end

  # The SubjectConfirmationData of the FIRST bearer SubjectConfirmation in the
  # Subject (S9). A non-bearer confirmation is ignored.
  defp bearer_subject_confirmation_data(%Node{} = assertion) do
    with %Node{} = subject <- first_direct_child(assertion, "Subject"),
         %Node{} = confirmation <- bearer_subject_confirmation(subject) do
      first_direct_child(confirmation, "SubjectConfirmationData")
    else
      _ -> nil
    end
  end

  defp bearer_subject_confirmation(%Node{} = subject) do
    subject
    |> direct_children_ns("SubjectConfirmation", [@saml_assertion_ns])
    |> Enum.find(fn sc -> attr(sc, "Method") == @bearer_method end)
  end

  # Bind the signature structurally to the Assertion (S1-S4): the ds:Signature
  # MUST be the enveloped, direct-child Signature of the bound Assertion, in the
  # XMLDSig namespace. Its SignedInfo must carry exactly ONE Reference whose URI
  # is "#" <> Assertion@ID, and DigestValue / DigestMethod / Transforms must be
  # that Reference's own direct children. The crypto methods come from the bound
  # SignedInfo, never a document-wide search.
  defp signature_fields(%Node{} = root, %Node{} = assertion) do
    with {:ok, candidate} <- bind_signature_candidate(assertion) do
      fields = %{
        signature_method: candidate.signature_method,
        digest_method: candidate.digest_method,
        canonicalization_method: candidate.canonicalization_method,
        signed_candidates: [candidate],
        duplicate_ids: duplicate_ids(root),
        key_info_trust: rogue_key_info_present?(root)
      }

      require_present_fields(
        fields,
        [:signature_method, :digest_method, :signed_candidates],
        :missing_signature,
        "Signed XML material is missing required signature fields"
      )
    end
  end

  defp bind_signature_candidate(%Node{} = assertion) do
    assertion_id = attr(assertion, "ID")

    with {:ok, signature} <- enveloped_signature(assertion),
         {:ok, signed_info} <- direct_child_required(signature, "SignedInfo", @dsig_ns),
         {:ok, reference} <- single_reference(signed_info),
         :ok <- reference_uri_matches(reference, assertion_id) do
      transforms_node = first_direct_child(reference, "Transforms")
      digest_method = first_attr_in(reference, "DigestMethod", "Algorithm")
      digest_value = direct_child_text(reference, "DigestValue")
      signature_value = direct_child_text(signature, "SignatureValue")
      signature_method = first_attr_in(signed_info, "SignatureMethod", "Algorithm")
      canonicalization_method = first_attr_in(signed_info, "CanonicalizationMethod", "Algorithm")

      {:ok,
       %{
         xml_id: assertion_id,
         xpath: "/Response/Assertion[1]",
         signed_xml: render_signed_xml(assertion),
         node: assertion,
         signature_node: signature,
         transforms_node: transforms_node,
         signed_info_node: signed_info,
         digest_value_b64: digest_value,
         signature_value_b64: signature_value,
         signature_method: signature_method,
         digest_method: digest_method,
         canonicalization_method: canonicalization_method
       }}
    end
  end

  # The signature MUST be a direct child of the bound Assertion (enveloped) in
  # the XMLDSig namespace (S3). A Signature elsewhere in the document, or nested
  # below the Assertion but not a direct child, is not a valid binding.
  defp enveloped_signature(%Node{} = assertion) do
    case direct_children_ns(assertion, "Signature", [@dsig_ns]) do
      [%Node{} = signature] ->
        {:ok, signature}

      [] ->
        {:error,
         Error.new(
           :signature_placement_invalid,
           "The bound <Assertion> has no enveloped direct-child <ds:Signature>",
           %{}
         )}

      multiple ->
        {:error,
         Error.new(
           :signature_placement_invalid,
           "The bound <Assertion> carries more than one direct-child <ds:Signature>",
           %{signature_count: length(multiple)}
         )}
    end
  end

  defp single_reference(%Node{} = signed_info) do
    case direct_children_ns(signed_info, "Reference", [@dsig_ns]) do
      [%Node{} = reference] ->
        {:ok, reference}

      references ->
        {:error,
         Error.new(
           :reference_mismatch,
           "SignedInfo must carry exactly one Reference",
           %{reference_count: length(references)}
         )}
    end
  end

  defp reference_uri_matches(%Node{} = reference, assertion_id)
       when is_binary(assertion_id) and assertion_id != "" do
    if attr(reference, "URI") == "#" <> assertion_id do
      :ok
    else
      {:error,
       Error.new(
         :reference_mismatch,
         "Reference URI does not match the bound Assertion ID",
         %{reference_uri: attr(reference, "URI"), assertion_id: assertion_id}
       )}
    end
  end

  defp reference_uri_matches(%Node{} = reference, _assertion_id) do
    {:error,
     Error.new(
       :reference_mismatch,
       "Signed Assertion has no ID for the Reference URI to bind to",
       %{reference_uri: attr(reference, "URI")}
     )}
  end

  defp direct_child_required(%Node{} = parent, local, uri) do
    case first_direct_child_ns(parent, local, [uri]) do
      %Node{} = node ->
        {:ok, node}

      _ ->
        {:error,
         Error.new(
           :missing_signature,
           "Signed material is missing a required <#{local}>",
           %{}
         )}
    end
  end

  # A ds:KeyInfo INSIDE a ds:Signature is standard XMLDSig and harmless — the
  # verifier never reads it, always using the operator-configured certificates
  # (CLAUDE.md #1). A KeyInfo OUTSIDE any Signature is a document trying to place
  # trust material where it does not belong; it is flagged, and
  # select_signed_node/2 rejects the document (:untrusted_certificate).
  defp rogue_key_info_present?(%Node{} = root) do
    has_rogue_key_info?(root, false)
  end

  defp has_rogue_key_info?(%Node{local: "KeyInfo"}, false), do: true
  defp has_rogue_key_info?(%Node{local: "KeyInfo"}, true), do: false

  defp has_rogue_key_info?(%Node{local: "Signature", children: children}, _inside?) do
    Enum.any?(children, &has_rogue_key_info?(&1, true))
  end

  defp has_rogue_key_info?(%Node{children: children}, inside?) when is_list(children) do
    Enum.any?(children, &has_rogue_key_info?(&1, inside?))
  end

  defp has_rogue_key_info?(_node, _inside?), do: false

  # All ID/id attribute values across the tree; return the values that occur more
  # than once (D-09 duplicate-ID guard, tree-derived). Document-order preserved
  # so the rejection details match the regex era (repeated occurrences listed).
  defp duplicate_ids(%Node{} = root) do
    ids =
      root
      |> all_nodes()
      |> Enum.flat_map(fn %Node{attrs: attrs} ->
        for {name, value} <- attrs, name in ["ID", "id"], do: value
      end)

    frequencies = Enum.frequencies(ids)
    Enum.filter(ids, fn id -> Map.get(frequencies, id, 0) > 1 end)
  end

  # Build the attribute map from <Attribute Name="..."><AttributeValue>..</> nodes.
  defp derive_attributes(%Node{} = root) do
    root
    |> find_all("Attribute")
    |> Enum.flat_map(fn %Node{} = attribute ->
      case attr(attribute, "Name") do
        nil ->
          []

        name ->
          values =
            attribute
            |> find_all("AttributeValue")
            |> Enum.map(&trimmed_text/1)

          [{name, values}]
      end
    end)
    |> Map.new()
  end

  @impl true
  def select_signed_node(parsed_doc, opts \\ [])

  def select_signed_node(parsed_doc, _opts) when is_map(parsed_doc) do
    duplicate_xml_ids = Map.get(parsed_doc, :duplicate_ids, [])

    cond do
      Map.get(parsed_doc, :key_info_trust) == true ->
        {:error,
         Error.new(
           :untrusted_certificate,
           "Document-provided KeyInfo cannot be used as a trust source",
           %{reason: :document_keyinfo_forbidden}
         )}

      duplicate_xml_ids != [] ->
        {:error,
         Error.new(
           :duplicate_xml_id,
           "Duplicate XML IDs detected in signed material",
           %{
             duplicate_ids: duplicate_xml_ids,
             duplicate_count: length(duplicate_xml_ids)
           }
         )}

      true ->
        select_candidate(parsed_doc)
    end
  end

  def select_signed_node(_parsed_doc, _opts) do
    {:error, Error.new(:missing_signature, "No signed node candidates were verified", %{})}
  end

  @impl true
  def canonicalize(signed_node_handle, opts \\ [])

  # A handle that binds a complete tree node (D-10): delegate to the Plan-02 C14N
  # engine, applying the signed Reference's transform chain over the EXACT bound
  # node (the same node select_signed_node/2 returned). The transform chain +
  # PrefixList are read from the bound ds:Signature's ds:Transforms node; the
  # SPECIFIC ds:Signature subtree is supplied so the enveloped-signature
  # transform prunes only that signature (anti-XSW). No ds:Transforms present =>
  # empty transform list (no prune, plain exclusive-C14N) — see canonicalize/2
  # binding note in 28-03-SUMMARY.md.
  def canonicalize(%{node: %Node{} = node} = handle, _opts) do
    transforms_node = Map.get(handle, :transforms_node)
    signature_node = Map.get(handle, :signature_node)
    transform_uris = C14N.transform_uris(transforms_node)
    prefix_list = C14N.prefix_list_from_transforms(transforms_node)

    cond do
      # Fail-closed hardening (trust path): a Reference that requests the
      # enveloped-signature transform but whose bound ds:Signature node cannot be
      # resolved MUST NOT serialize-without-pruning — that would leave signature
      # material in the canonical bytes (a fail-OPEN on the auth path). The C14N
      # engine treats a nil signature subtree as "no prune", so guard here.
      @enveloped_signature in transform_uris and not is_struct(signature_node, Node) ->
        {:error,
         Error.new(
           :canonicalization_failed,
           "Signed node handle could not be canonicalized",
           %{reason: :enveloped_signature_unresolved}
         )}

      true ->
        case C14N.canonicalize_reference(node, transform_uris, signature_node,
               prefix_list: prefix_list
             ) do
          {:ok, canonical_bytes} ->
            {:ok,
             %{
               canonical_xml: canonical_bytes,
               xml_id: Map.get(handle, :xml_id),
               xpath: Map.get(handle, :xpath)
             }}

          {:error, %Error{} = error} ->
            {:error, error}
        end
    end
  end

  # Fail-closed fallback (Pitfall 9 / GATE-02 contract, threat T-28-12): any
  # handle lacking a bindable tree node — including the whole parsed_doc map the
  # corpus c14n-00x rows pass, and a bare atom handle (seam_contract) — is
  # rejected. The real engine must NOT succeed on incomplete / differential
  # inputs.
  def canonicalize(_signed_node_handle, _opts) do
    {:error,
     Error.new(
       :canonicalization_failed,
       "Signed node handle could not be canonicalized",
       %{reason: :invalid_signed_node_handle}
     )}
  end

  defp select_candidate(parsed_doc) do
    signed_candidates = Map.get(parsed_doc, :signed_candidates, [])
    signature_method = Map.get(parsed_doc, :signature_method)
    digest_method = Map.get(parsed_doc, :digest_method)

    case signed_candidates do
      [] ->
        {:error, Error.new(:missing_signature, "No signed node candidates were verified", %{})}

      [candidate] when is_map(candidate) ->
        # The legacy flat keys stay for backward-compat (D-08); :node /
        # :signature_node / :transforms_node are carried additively (D-10) so
        # canonicalize/2 serializes the EXACT bound node. :signed_info_node /
        # :digest_value_b64 / :signature_value_b64 (D-02) carry the crypto inputs
        # onto the handle so signature.ex (Plan 03) reads them off it.
        {:ok,
         %{
           xml_id: Map.get(candidate, :xml_id),
           xpath: Map.get(candidate, :xpath),
           signed_xml: Map.get(candidate, :signed_xml),
           signature_method: Map.get(candidate, :signature_method, signature_method),
           digest_method: Map.get(candidate, :digest_method, digest_method),
           node: Map.get(candidate, :node),
           signature_node: Map.get(candidate, :signature_node),
           transforms_node: Map.get(candidate, :transforms_node),
           signed_info_node: Map.get(candidate, :signed_info_node),
           digest_value_b64: Map.get(candidate, :digest_value_b64),
           signature_value_b64: Map.get(candidate, :signature_value_b64)
         }}

      candidates ->
        {:error,
         Error.new(
           :ambiguous_signed_node,
           "Exactly one verified signed node is required",
           %{candidate_count: length(candidates)}
         )}
    end
  end

  defp require_present_fields(fields, required_keys, error_type, message) do
    missing =
      Enum.reject(required_keys, fn key ->
        present?(Map.get(fields, key))
      end)

    if missing == [] do
      {:ok, fields}
    else
      {:error,
       Error.new(error_type, message, %{
         expected: required_keys,
         actual: required_keys -- missing,
         missing: missing
       })}
    end
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value) when is_list(value), do: value != []
  defp present?(value), do: not is_nil(value)

  # --- tree-walk derivation helpers ------------------------------------------

  # The first descendant-or-self element with the given local name, in document
  # order, or nil.
  defp find_first(%Node{local: local} = node, local), do: node

  defp find_first(%Node{children: children}, local) do
    Enum.find_value(children, fn child -> find_first(child, local) end)
  end

  defp find_first(_other, _local), do: nil

  # The first DIRECT child element with the given local name, in document order,
  # or nil. Unlike find_first/2 (descendant-or-self), this does NOT descend past
  # the immediate children — used to bind the metadata-root's own ds:Signature
  # (not a Signature buried in a nested KeyDescriptor / EntityDescriptor).
  defp direct_child(%Node{children: children}, local) do
    Enum.find(children, fn
      %Node{local: ^local} -> true
      _ -> false
    end)
  end

  defp direct_child(_other, _local), do: nil

  # The resolved namespace URI of a node (the in-scope URI for its prefix; the
  # default-namespace "" key for an unprefixed element), or nil when none is in
  # scope.
  defp ns_uri(%Node{prefix: prefix, ns: ns}), do: Map.get(ns, prefix)

  # True when the node's local name matches AND its namespace is one of `uris`
  # (or the element carries no namespace at all — an unqualified element inside a
  # signed subtree is covered by the signature). A FOREIGN namespace never
  # matches (S20): a lookalike <x:NameID xmlns:x="urn:attacker"> is rejected.
  defp ns_match?(%Node{local: local} = node, local, uris) do
    case ns_uri(node) do
      nil -> true
      "" -> true
      uri -> uri in uris
    end
  end

  defp ns_match?(_node, _local, _uris), do: false

  # Direct children (not descendants) with the given local name and an allowed
  # namespace, in document order.
  defp direct_children_ns(%Node{children: children}, local, uris) do
    Enum.filter(children, &ns_match?(&1, local, uris))
    |> Enum.filter(fn %Node{local: l} -> l == local end)
  end

  defp direct_children_ns(_other, _local, _uris), do: []

  defp first_direct_child_ns(node, local, uris) do
    node |> direct_children_ns(local, uris) |> List.first()
  end

  # Direct child by local name, any namespace (used for Response-envelope
  # elements and the Subject/NameID walk, which are structural position checks).
  defp first_direct_child(%Node{children: children}, local) do
    Enum.find(children, fn %Node{local: l} -> l == local end)
  end

  defp first_direct_child(_other, _local), do: nil

  # Trimmed text of the first direct child with this local name, or nil.
  defp direct_child_text(%Node{} = node, local) do
    case first_direct_child(node, local) do
      %Node{} = child -> trimmed_text(child)
      _ -> nil
    end
  end

  defp direct_child_text(_other, _local), do: nil

  # First descendant-or-self with this local name and an allowed namespace.
  defp first_descendant_ns(%Node{local: local} = node, local) do
    if ns_match?(node, local, [@saml_assertion_ns]), do: node, else: descend_ns(node, local)
  end

  defp first_descendant_ns(%Node{} = node, local), do: descend_ns(node, local)
  defp first_descendant_ns(_other, _local), do: nil

  defp descend_ns(%Node{children: children}, local) do
    Enum.find_value(children, fn child -> first_descendant_ns(child, local) end)
  end

  # first_attr/3 starting from a possibly-nil parent (e.g. an absent SignedInfo):
  # the value of the first descendant-or-self element (with this local name)
  # carrying the given attribute, trimmed; or nil. nil-safe.
  defp first_attr_in(%Node{} = node, local, attribute_name),
    do: first_attr(node, local, attribute_name)

  defp first_attr_in(_other, _local, _attribute_name), do: nil

  # All descendant-or-self elements with the given local name, in document order.
  defp find_all(%Node{} = node, local) do
    node
    |> collect(local, [])
    |> Enum.reverse()
  end

  defp collect(%Node{local: local, children: children} = node, local, acc) do
    Enum.reduce(children, [node | acc], fn child, a -> collect(child, local, a) end)
  end

  defp collect(%Node{children: children}, local, acc) do
    Enum.reduce(children, acc, fn child, a -> collect(child, local, a) end)
  end

  # Every element node in the tree, document order.
  defp all_nodes(%Node{} = root) do
    root
    |> collect_all([])
    |> Enum.reverse()
  end

  defp collect_all(%Node{children: children} = node, acc) do
    Enum.reduce(children, [node | acc], fn child, a -> collect_all(child, a) end)
  end

  # Trimmed text of every descendant-or-self element with this local name,
  # dropping empties (matches regex-era all_tag_texts/2).
  defp all_texts(%Node{} = root, local) do
    root
    |> find_all(local)
    |> Enum.map(&trimmed_text/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp trimmed_text(%Node{text: text}), do: String.trim(text)

  # nil-safe sibling lookup off a possibly-absent parent (e.g. no ds:Signature):
  # returns nil instead of raising when the parent is nil.
  defp maybe_find(%Node{} = node, local), do: find_first(node, local)
  defp maybe_find(_other, _local), do: nil

  # nil-safe trimmed text (D-02): mirrors trimmed_text/1 but returns nil when the
  # node is absent, so an absent DigestValue / SignatureValue yields nil (no raise).
  defp trimmed_node_text(%Node{} = node), do: trimmed_text(node)
  defp trimmed_node_text(_other), do: nil

  # The value of the first descendant-or-self element (with this local name)
  # carrying the given attribute, trimmed; or nil. Matches the regex-era
  # first_attribute/3 contract.
  defp first_attr(%Node{} = root, local, attribute_name) do
    root
    |> find_all(local)
    |> Enum.find_value(fn node -> attr(node, attribute_name) end)
  end

  # A single attribute value off a node, trimmed; or nil.
  defp attr(%Node{attrs: attrs}, attribute_name) do
    case List.keyfind(attrs, attribute_name, 0) do
      {_name, value} -> String.trim(value)
      nil -> nil
    end
  end

  defp attr(_other, _attribute_name), do: nil

  defp element_present?(%Node{} = root, local), do: find_first(root, local) != nil
  defp element_present?(_other, _local), do: false

  # A plain, deterministic XML serialization of a tree node for the legacy
  # :signed_xml backward-compat key (consumed only as an opaque binary by
  # do_verify). This is NOT canonical C14N — canonical bytes come from the C14N
  # engine via canonicalize/2 over the bound :node.
  defp render_signed_xml(%Node{qname: qname, attrs: attrs, children: children, text: text}) do
    attr_iodata = Enum.map(attrs, fn {name, value} -> [" ", name, "=\"", value, "\""] end)
    child_iodata = Enum.map(children, &render_signed_xml/1)
    IO.iodata_to_binary(["<", qname, attr_iodata, ">", text, child_iodata, "</", qname, ">"])
  end

  defp malformed_xml_error do
    {:error, Error.new(:malformed_xml, "Malformed XML payload", %{})}
  end
end
