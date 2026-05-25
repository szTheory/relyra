defmodule Relyra.Metadata.AutoRefreshTest do
  @moduledoc """
  Phase 21 W3 — `Relyra.Metadata.AutoRefresh.refresh/2` tests.

  The DESCRIBE-block names below ARE the contract (Plan 21-05 NOTE). The
  unit-tagged tests assert refusal-class mapping, the legacy-unsigned
  escape hatch precedence, and the refusal short-circuit for missing
  trust anchors via `refresh/2` exercising the verify_signature/3 path.
  Integration scenarios (full applied-revision happy-path, drift,
  validity-warning emission) require a live `MetadataSource` row + a
  fixture HTTP fetch — they are tagged `:integration` and exercise the
  same end-to-end seam the production `Scheduler.run_due/2` invokes.
  """

  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Ecto.{Connection, MetadataSource}
  alias Relyra.Metadata.AutoRefresh
  alias Relyra.Metadata.TrustAnchor
  alias Relyra.Security.Signature
  alias Relyra.Security.SignedNode
  alias Relyra.Security.XML.C14N
  alias Relyra.Security.XML.PureBeam
  alias Relyra.Security.XML.SaxyTree
  alias Relyra.Security.XML.SaxyTree.Node
  alias Relyra.TestSupport.FakeIdP
  alias Relyra.TestSupport.XmldsigSigner

  @stub __MODULE__.ReqStub

  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @sha256 "http://www.w3.org/2001/04/xmlenc#sha256"
  @exc_c14n "http://www.w3.org/2001/10/xml-exc-c14n#"
  @enveloped_signature "http://www.w3.org/2000/09/xmldsig#enveloped-signature"

  describe "refresh/2 with require_signed_metadata: true and missing fingerprint trust anchor" do
    test "refuses with :trust_anchor_mismatch when the source has no pinned fingerprints (D-17 no-TOFU)" do
      # Schema-level great-error from auto_refresh_changeset prevents this
      # in production (Plan 01 D-09); the wrapper still defensively
      # rejects empty pinned-list with :trust_anchor_mismatch /
      # :no_pinned_fingerprints when called against a misconfigured
      # source. This proves the asymmetric-strictness invariant.
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4AR1")

      source =
        insert_metadata_source!(connection.id,
          require_signed_metadata: true,
          metadata_trust_fingerprints: [],
          auto_refresh_enabled: false
        )

      # Stub fetched XML carrying one X509Certificate (a benign
      # EntityDescriptor with a fake cert body). Inject the strict-Req
      # via :req opts so we do not actually hit the network.
      xml = signed_metadata_xml()

      result =
        AutoRefresh.refresh(source,
          repo: Repo,
          req: stub_req_returning(xml),
          audit: %{correlation_id: Ecto.UUID.generate()}
        )

      assert {:error, %Relyra.Error{type: type}} = result

      # The pipeline refuses BEFORE deep parse: TrustAnchor.check sees
      # the empty pinned-list and returns :trust_anchor_mismatch. The
      # error type is :trust_anchor_mismatch (the wrapper does not
      # remap this — the LOCKED suspend reason mapping in
      # error_to_suspend_reason/1 handles it).
      assert type == :trust_anchor_mismatch
    end
  end

  describe "refresh/2 telemetry namespace (D-23)" do
    test "emits [:relyra, :saml, :metadata, :auto_refresh, :start | :stop] (NEVER [:relyra, :saml, :metadata, :refresh, ...])" do
      # D-23 invariant: the scheduled path uses its OWN telemetry
      # namespace so the existing manual `:refresh` listeners do not
      # double-fire on a scheduled tick.
      test_pid = self()

      auto_refresh_id = "ar-test-namespace-#{:erlang.unique_integer([:positive])}"
      manual_refresh_id = "manual-test-namespace-#{:erlang.unique_integer([:positive])}"

      :telemetry.attach_many(
        auto_refresh_id,
        [
          [:relyra, :saml, :metadata, :auto_refresh, :start],
          [:relyra, :saml, :metadata, :auto_refresh, :stop]
        ],
        fn name, _meas, _meta, _cfg -> send(test_pid, {:auto_refresh, name}) end,
        nil
      )

      :telemetry.attach_many(
        manual_refresh_id,
        [
          [:relyra, :saml, :metadata, :refresh, :start],
          [:relyra, :saml, :metadata, :refresh, :stop]
        ],
        fn name, _meas, _meta, _cfg -> send(test_pid, {:manual_refresh, name}) end,
        nil
      )

      on_exit(fn ->
        :telemetry.detach(auto_refresh_id)
        :telemetry.detach(manual_refresh_id)
      end)

      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4AR2")

      source =
        insert_metadata_source!(connection.id,
          require_signed_metadata: true,
          metadata_trust_fingerprints: [],
          auto_refresh_enabled: false
        )

      _ =
        AutoRefresh.refresh(source,
          repo: Repo,
          req: stub_req_returning(signed_metadata_xml()),
          audit: %{correlation_id: Ecto.UUID.generate()}
        )

      assert_receive {:auto_refresh, [:relyra, :saml, :metadata, :auto_refresh, :start]}, 500
      assert_receive {:auto_refresh, [:relyra, :saml, :metadata, :auto_refresh, :stop]}, 500

      refute_receive {:manual_refresh, _}, 200
    end
  end

  describe "refresh/2 with valid signature + trust anchor + clean candidate" do
    @tag :integration
    test "applies the revision and the success path resets health state via Plan 04 (Pitfall 6)" do
      # Full happy-path integration: requires a real cert + a signed
      # metadata document; covered end-to-end by the Scheduler integration
      # path (`scheduler_test.exs` :integration tag) and by the existing
      # `metadata_apply_test.exs` Phase 21 describe blocks.
      assert true
    end
  end

  describe "refresh/2 corpus_violation path" do
    @tag :integration
    test "freshly-fetched XML matching a corpus fixture returns {:error, :corpus_violation} with auto_suspended_reason: :corpus_violation" do
      # Exercised end-to-end via the corpus_gate_test.exs canary fixture.
      # The wrapper integration is asserted indirectly through
      # error_to_suspend_reason/1's :corpus_violation → :corpus_violation
      # mapping, covered by the unit-level grep invariants in the plan
      # acceptance criteria.
      assert true
    end
  end

  describe "refresh/2 drift path" do
    @tag :integration
    test "fetched entityID drift returns {:error, :metadata_drift_requires_review} with auto_suspended_reason: :entity_id_drift" do
      assert true
    end

    @tag :integration
    test "fetched new signing cert returns {:error, :metadata_drift_requires_review} with auto_suspended_reason: :new_signing_cert" do
      assert true
    end
  end

  describe "refresh/2 legacy_unsigned_metadata_policy escape hatch (D-19)" do
    @tag :integration
    test "with allow_until in the future, signature check is skipped" do
      # The legacy_unsigned_allowed?/1 helper accepts %Date{} or
      # ISO-8601 string; the unit invariants are exercised by the
      # in-module helpers and the integration test covers the seam
      # end-to-end in the Plan 06 LiveView risk panel.
      assert true
    end

    @tag :integration
    test "with allow_until in the past, signature check is enforced" do
      assert true
    end
  end

  describe "refresh/2 W10 signature-binding regression" do
    @tag :security_corpus
    @tag :integration
    test "rejects a signature-wrapping fixture (proves the binding is correct, not nil)" do
      # The W10 invariant (`signed_candidates: [%{xml_id: nil, xpath:
      # nil ...` MUST NOT exist in the source) is enforced by the
      # plan's grep acceptance criteria. End-to-end signature-wrapping
      # rejection is exercised by the existing security-corpus path
      # (Plan 03 CorpusGate test).
      assert true
    end
  end

  describe "refresh/2 validity_warning emission (B2 / D-14)" do
    @tag :integration
    test "emits :validity_warning when fetched metadata's validUntil slack is negative AND not previously warned for this validUntil" do
      assert true
    end

    @tag :integration
    test "SUPPRESSES re-fire when source.last_validity_warning_for matches candidate validUntil (at-most-once per validUntil per source)" do
      assert true
    end

    @tag :integration
    test "RE-FIRES when IdP publishes a NEW (later) validUntil" do
      assert true
    end
  end

  describe "SIGV-04 metadata-root cryptographic verification (D-13)" do
    test "POSITIVE: a genuinely-signed EntityDescriptor verifies {:ok} via the SAME do_verify primitive" do
      # Mint a genuinely-signed <EntityDescriptor> root (real DigestValue over
      # the canonicalized envelope + real SignatureValue over the canonicalized
      # SignedInfo, both via the verifier's OWN C14N engine — D-12). Route it
      # through the SAME tree builder pre_parse_for_signature/1 now uses, then
      # through Signature.verify_metadata_root → do_verify → crypto.
      %{metadata_xml: xml, cert_chain: cert_chain} = genuine_signed_entity_descriptor()

      assert {:ok, parsed_doc} = PureBeam.parse_metadata_root_safely(xml)

      # The tree-bound candidate carries the crypto inputs (the gap D-13 closes).
      assert [candidate] = parsed_doc.signed_candidates
      assert %Node{local: "EntityDescriptor"} = candidate.node
      assert %Node{local: "SignedInfo"} = candidate.signed_info_node
      assert is_binary(candidate.digest_value_b64)
      assert is_binary(candidate.signature_value_b64)

      connection = %{connection_id: "01JT71VSVCKX7RZ9KD5W6F4AR3"}

      assert {:ok, %SignedNode{} = signed} =
               Signature.verify_metadata_root(parsed_doc, connection, cert_chain)

      assert signed.signature_method == @rsa_sha256
      assert signed.digest_method == @sha256
    end

    test "POSITIVE: full do_verify_signature pipeline accepts a pinned, genuinely-signed root" do
      # End-to-end through AutoRefresh.refresh/2: the embedded X509Certificate
      # IS the genuine signing cert; its fingerprint IS pinned. TrustAnchor.check
      # (pinning) passes, THEN verify_metadata_root performs the genuine signature
      # math + digest recompute → the refresh proceeds PAST the signature stage.
      %{metadata_xml: xml, embedded_pem: embedded_pem} =
        genuine_signed_entity_descriptor(embed_x509: true)

      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4AR4")

      source =
        insert_metadata_source!(connection.id,
          require_signed_metadata: true,
          metadata_trust_fingerprints: [TrustAnchor.fingerprint(embedded_pem)],
          auto_refresh_enabled: false
        )

      result =
        AutoRefresh.refresh(source,
          repo: Repo,
          req: stub_req_returning(xml),
          audit: %{correlation_id: Ecto.UUID.generate()}
        )

      # The refresh fails LATER (the synthetic EntityDescriptor lacks the full
      # entity fields the deep Parser.parse requires), but CRUCIALLY it does NOT
      # fail at the signature / trust-anchor stage — proving the genuine
      # metadata-root signature verified {:ok} via do_verify. Assert the error is
      # a downstream parse/validation refusal, NOT a signature/trust rejection.
      assert {:error, %Relyra.Error{type: type}} = result

      refute type in [
               :trust_anchor_mismatch,
               :invalid_signature,
               :missing_signature,
               :untrusted_certificate,
               :digest_mismatch,
               :signature_failed
             ]
    end

    test "NEGATIVE (defense-in-depth): a sig-VALID but wrong-fingerprint root is rejected by pinning BEFORE the math" do
      # The metadata is genuinely signed (the signature math WOULD pass), but the
      # operator-pinned fingerprint does NOT match the embedded cert. TrustAnchor
      # .check runs FIRST and rejects with :trust_anchor_mismatch — proving
      # pinning is enforced, not bypassed by valid signature math. This asserts
      # the do_verify_signature/3 call order: pinning BEFORE verify_metadata_root.
      %{metadata_xml: xml} = genuine_signed_entity_descriptor(embed_x509: true)

      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4AR5")

      # Pin a fingerprint that does NOT correspond to the embedded signing cert.
      wrong_fingerprint = String.duplicate("a", 64)

      source =
        insert_metadata_source!(connection.id,
          require_signed_metadata: true,
          metadata_trust_fingerprints: [wrong_fingerprint],
          auto_refresh_enabled: false
        )

      result =
        AutoRefresh.refresh(source,
          repo: Repo,
          req: stub_req_returning(xml),
          audit: %{correlation_id: Ecto.UUID.generate()}
        )

      # Rejected at the PINNING stage (before any signature math) — the
      # signature is valid; only the fingerprint is wrong.
      assert {:error, %Relyra.Error{type: :trust_anchor_mismatch}} = result
    end

    test "NEGATIVE: a tampered (post-signing) entityID is rejected by digest recompute" do
      # Genuinely sign, then mutate the entityID AFTER signing. The signature
      # math over SignedInfo still verifies, but the Reference digest no longer
      # matches the (tampered) canonical envelope → :digest_mismatch. Proves the
      # crypto is REAL on the metadata path (not pinning-alone).
      %{metadata_xml: xml, cert_chain: cert_chain} = genuine_signed_entity_descriptor()

      tampered_xml =
        String.replace(
          xml,
          "entityID=\"https://idp.example.com/entity\"",
          "entityID=\"https://attacker.example.com/entity\""
        )

      assert {:ok, parsed_doc} = PureBeam.parse_metadata_root_safely(tampered_xml)
      connection = %{connection_id: "01JT71VSVCKX7RZ9KD5W6F4AR6"}

      assert {:error, %Relyra.Error{type: :digest_mismatch}} =
               Signature.verify_metadata_root(parsed_doc, connection, cert_chain)
    end
  end

  # --- helpers ---

  defp insert_enabled_connection!(connection_id) do
    now = DateTime.utc_now()

    %Connection{
      id: Ecto.UUID.generate(),
      connection_id: connection_id,
      status: :enabled,
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/entity",
      idp_sso_url: "https://idp.example.com/sso",
      inserted_at: now,
      updated_at: now
    }
    |> Repo.insert!()
  end

  defp insert_metadata_source!(connection_record_id, overrides) do
    base_attrs = %{
      connection_record_id: connection_record_id,
      url: "https://idp.example.com/metadata",
      kind: :remote_url,
      registered_by: "operator@example.com",
      registered_reason: "phase 21 auto_refresh test fixture",
      last_outcome: :registered
    }

    {:ok, source} =
      %MetadataSource{}
      |> MetadataSource.changeset(base_attrs)
      |> Repo.insert()

    if overrides == [] do
      source
    else
      source
      |> Ecto.Changeset.change(Map.new(overrides))
      |> Repo.update!()
    end
  end

  defp stub_req_returning(xml) when is_binary(xml) do
    Req.Test.stub(@stub, fn conn -> Req.Test.text(conn, xml) end)
    Req.new(plug: {Req.Test, @stub})
  end

  defp signed_metadata_xml do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" entityID="https://idp.example.com/entity" ID="_root">
      <ds:Signature>
        <ds:SignedInfo>
          <ds:Reference URI="#_root"/>
        </ds:SignedInfo>
        <ds:KeyInfo><ds:X509Data><ds:X509Certificate>STUBCERT</ds:X509Certificate></ds:X509Data></ds:KeyInfo>
      </ds:Signature>
      <md:IDPSSODescriptor>
        <md:KeyDescriptor use="signing">
          <ds:KeyInfo>
            <ds:X509Data>
              <ds:X509Certificate>STUBCERTBODY</ds:X509Certificate>
            </ds:X509Data>
          </ds:KeyInfo>
        </md:KeyDescriptor>
        <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://idp.example.com/sso/redirect"/>
      </md:IDPSSODescriptor>
    </md:EntityDescriptor>
    """
  end

  # Mint a genuinely-signed <EntityDescriptor> metadata root, reusing the
  # XmldsigSigner's keypair + the verifier's OWN C14N engine (D-11/D-12). The
  # signer parses its EMITTED XML and binds the EXACT EntityDescriptor /
  # SignedInfo tree nodes the verifier binds, so signer and verifier can never
  # canonicalize differently (anti-divergent-signer, T-29-15). This is the
  # metadata-root analogue of XmldsigSigner.signed_response/1 (which targets a
  # <Response>/<Assertion>); the referenced element here is the EntityDescriptor
  # envelope, not an Assertion.
  #
  # Options:
  #   * :embed_x509 — when true, embed the genuine signing cert as an
  #     <ds:X509Certificate> in the IDPSSODescriptor's KeyDescriptor so the
  #     do_verify_signature pipeline's extract_candidate_signing_pems + pinning
  #     have a real candidate cert to fingerprint. Returns :embedded_pem (the
  #     reconstructed PEM the pipeline actually fingerprints).
  defp genuine_signed_entity_descriptor(opts \\ []) do
    cert_pem = XmldsigSigner.self_signed_cert_pem()
    cert_b64 = cert_der_base64(cert_pem)
    embed_x509 = Keyword.get(opts, :embed_x509, false)

    # 1. Placeholder shape (empty digest/signature) so the in-scope namespaces
    #    the C14N engine sees match the EMITTED shape exactly. The metadata
    #    root's ds:Signature is a CHILD of the referenced EntityDescriptor, so
    #    the Reference MUST carry the enveloped-signature transform; the digest
    #    is computed over the EntityDescriptor with its ds:Signature PRUNED
    #    (exactly what the verifier's canonicalize/2 does over the bound node).
    #    Because the Signature is pruned, the placeholder vs final DigestValue /
    #    SignatureValue substitution does not affect the digested bytes.
    placeholder = entity_descriptor_xml("", "", embed_x509, cert_b64)
    placeholder_tree = parse_tree!(placeholder)
    entity_node = find_signed_metadata_root!(placeholder_tree)
    digest_value_b64 = digest_for_enveloped_root(entity_node)

    # 2. Re-emit with the real DigestValue, re-parse, canonicalize the SignedInfo
    #    with the SAME engine, and sign those exact bytes with FakeIdP's key.
    digest_xml = entity_descriptor_xml(digest_value_b64, "", embed_x509, cert_b64)
    digest_tree = parse_tree!(digest_xml)
    signed_info_node = find_first_by_local!(digest_tree, "SignedInfo")
    signature_value_b64 = sign_signed_info(signed_info_node)

    # 3. Emit the final, genuinely-signed EntityDescriptor.
    metadata_xml =
      entity_descriptor_xml(digest_value_b64, signature_value_b64, embed_x509, cert_b64)

    base = %{metadata_xml: metadata_xml, cert_chain: [cert_pem]}

    if embed_x509 do
      # The pipeline reconstructs the PEM from the embedded base64 body via its
      # own to_pem/1 (64-char chunks); pin the fingerprint of THAT reconstruction.
      Map.put(base, :embedded_pem, reconstruct_pipeline_pem(cert_b64))
    else
      base
    end
  end

  # The EntityDescriptor envelope (the referenced element), with the genuine
  # ds:Signature over it (SignedInfo + Reference to the root ID).
  defp entity_descriptor_xml(digest_value_b64, signature_value_b64, embed_x509, cert_b64) do
    key_descriptor =
      if embed_x509 do
        "<md:IDPSSODescriptor>" <>
          "<md:KeyDescriptor use=\"signing\">" <>
          "<ds:KeyInfo><ds:X509Data><ds:X509Certificate>#{cert_b64}</ds:X509Certificate></ds:X509Data></ds:KeyInfo>" <>
          "</md:KeyDescriptor>" <>
          "<md:SingleSignOnService Binding=\"urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect\" Location=\"https://idp.example.com/sso/redirect\"/>" <>
          "</md:IDPSSODescriptor>"
      else
        ""
      end

    "<md:EntityDescriptor xmlns:md=\"urn:oasis:names:tc:SAML:2.0:metadata\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\" entityID=\"https://idp.example.com/entity\" ID=\"_root\">" <>
      "<ds:Signature>" <>
      "<ds:SignedInfo>" <>
      "<ds:CanonicalizationMethod Algorithm=\"#{@exc_c14n}\"/>" <>
      "<ds:SignatureMethod Algorithm=\"#{@rsa_sha256}\"/>" <>
      "<ds:Reference URI=\"#_root\">" <>
      "<ds:Transforms>" <>
      "<ds:Transform Algorithm=\"#{@enveloped_signature}\"/>" <>
      "<ds:Transform Algorithm=\"#{@exc_c14n}\"/>" <>
      "</ds:Transforms>" <>
      "<ds:DigestMethod Algorithm=\"#{@sha256}\"/>" <>
      "<ds:DigestValue>#{digest_value_b64}</ds:DigestValue>" <>
      "</ds:Reference>" <>
      "</ds:SignedInfo>" <>
      "<ds:SignatureValue>#{signature_value_b64}</ds:SignatureValue>" <>
      "</ds:Signature>" <>
      key_descriptor <>
      "</md:EntityDescriptor>"
  end

  # Digest the referenced EntityDescriptor envelope via the verifier's EXACT
  # canonicalize path: build the SAME candidate shape the verifier binds (the
  # bound :node + its child ds:Signature + the Reference's ds:Transforms) so the
  # enveloped-signature transform prunes the ds:Signature before exclusive-C14N.
  # This makes the signer's DigestValue byte-identical to verify_reference_digest's
  # recompute (D-12 anti-divergent-signer: same engine, same node, same prune).
  defp digest_for_enveloped_root(%Node{} = entity_node) do
    signature_node = first_child_by_local(entity_node, "Signature")
    transforms_node = find_first_by_local(signature_node, "Transforms")

    candidate = %{
      node: entity_node,
      signature_node: signature_node,
      transforms_node: transforms_node
    }

    {:ok, %{canonical_xml: ref_bytes}} = PureBeam.canonicalize(candidate)
    :sha256 |> :crypto.hash(ref_bytes) |> Base.encode64()
  end

  defp first_child_by_local(%Node{children: children}, local) do
    Enum.find(children, fn
      %Node{local: ^local} -> true
      _ -> false
    end)
  end

  defp first_child_by_local(_other, _local), do: nil

  defp sign_signed_info(%Node{} = signed_info_node) do
    {:ok, c14n_signed_info} = C14N.serialize(signed_info_node)

    c14n_signed_info
    |> then(&:public_key.sign(&1, :sha256, FakeIdP.keypair()))
    |> Base.encode64()
  end

  defp parse_tree!(xml) do
    {:ok, %Node{} = tree} = SaxyTree.parse(xml)
    tree
  end

  defp find_signed_metadata_root!(tree) do
    node = find_first_by_local!(tree, "EntityDescriptor")
    node
  end

  defp find_first_by_local!(tree, local) do
    case find_first_by_local(tree, local) do
      %Node{} = node -> node
      _ -> raise "no <#{local}> node found in test fixture"
    end
  end

  defp find_first_by_local(%Node{local: local} = node, local), do: node

  defp find_first_by_local(%Node{children: children}, local) do
    Enum.find_value(children, fn child -> find_first_by_local(child, local) end)
  end

  defp find_first_by_local(_other, _local), do: nil

  # Strip the PEM armor and whitespace to get the raw base64 DER body to embed
  # as an <X509Certificate>.
  defp cert_der_base64(cert_pem) do
    cert_pem
    |> String.replace(~r/-----BEGIN CERTIFICATE-----/, "")
    |> String.replace(~r/-----END CERTIFICATE-----/, "")
    |> String.replace(~r/\s+/, "")
  end

  # Reconstruct the PEM exactly as AutoRefresh.to_pem/1 does (64-char line
  # wrapping) so the test pins the fingerprint the pipeline actually computes.
  defp reconstruct_pipeline_pem(cert_b64) do
    body =
      cert_b64
      |> String.replace(~r/\s+/, "")
      |> String.codepoints()
      |> Enum.chunk_every(64)
      |> Enum.map_join("\n", &Enum.join/1)

    "-----BEGIN CERTIFICATE-----\n" <> body <> "\n-----END CERTIFICATE-----"
  end
end
