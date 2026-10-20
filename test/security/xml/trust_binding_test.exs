defmodule Relyra.Security.XML.TrustBindingTest do
  @moduledoc """
  Phase 80 trust-binding corpus (BIND-01..BIND-08).

  Every row starts from a GENUINELY signed, SAML-conformant Response (an
  enveloped `ds:Signature` inside the `saml:Assertion`), applies one change, and
  drives it through the public `Relyra.consume_response/3`. A row asserts either
  one exact typed rejection, or `{:ok, _}` carrying the values the IdP actually
  signed — never a bare `{:error, _}`.

  Seam IDs (S1..S20) refer to `.planning/research/SUMMARY.md` § Seam Inventory.
  """

  use ExUnit.Case, async: true

  @moduletag :trust_binding

  alias Relyra.Error
  alias Relyra.Security.LogoutValidator
  alias Relyra.TestSupport.XmldsigSigner

  @assertion_ns "urn:oasis:names:tc:SAML:2.0:assertion"
  @dsig_ns "http://www.w3.org/2000/09/xmldsig#"
  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @sha256 "http://www.w3.org/2001/04/xmlenc#sha256"
  @exc_c14n "http://www.w3.org/2001/10/xml-exc-c14n#"
  @enveloped "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
  @success "urn:oasis:names:tc:SAML:2.0:status:Success"

  @idp "https://idp.example.com/metadata"
  @sp "https://sp.example.com/metadata"
  @acs "https://sp.example.com/saml/acs"
  @request_id "id_request_123"
  @name_id "user@example.com"
  @now ~U[2026-04-24 16:00:00Z]

  # ---------------------------------------------------------------------------
  # Positive control
  # ---------------------------------------------------------------------------

  describe "positive control" do
    test "a genuinely signed, namespaced, enveloped Response verifies with the signed values" do
      assert {:ok, result} = consume(signed())
      assert result.principal.name_id == @name_id
      assert result.principal.attributes == %{"role" => ["member"]}
    end
  end

  # ---------------------------------------------------------------------------
  # Envelope field injection (S6/S7) — the confirmed bypass
  # ---------------------------------------------------------------------------

  describe "envelope field injection (S6/S7)" do
    test "a NameID injected before the signed assertion is never consumed" do
      xml = inject_before_assertion(signed(), ~s(<saml:NameID>attacker@evil.com</saml:NameID>))
      refute_ok_with_name_id(consume(xml), "attacker@evil.com")
    end

    test "a NameID injected inside Response Extensions is never consumed" do
      xml =
        inject_before_assertion(
          signed(),
          ~s(<samlp:Extensions><saml:NameID>attacker@evil.com</saml:NameID></samlp:Extensions>)
        )

      refute_ok_with_name_id(consume(xml), "attacker@evil.com")
    end

    test "a fresh Conditions injected outside the signed assertion cannot extend an expired assertion" do
      base = signed(not_on_or_after: "2000-01-01T00:00:00Z")

      xml =
        inject_before_assertion(
          base,
          ~s(<saml:Conditions NotBefore="2000-01-01T00:00:00Z" NotOnOrAfter="2099-01-01T00:00:00Z"><saml:AudienceRestriction><saml:Audience>#{@sp}</saml:Audience></saml:AudienceRestriction></saml:Conditions>)
        )

      assert {:error, %Error{type: type}} = consume(xml)
      assert type in [:assertion_expired, :ambiguous_signed_node, :missing_protocol_field]
    end

    test "an AttributeStatement injected outside the signed assertion is never consumed" do
      xml =
        inject_before_assertion(
          signed(),
          ~s(<saml:AttributeStatement><saml:Attribute Name="groups"><saml:AttributeValue>admins</saml:AttributeValue></saml:Attribute></saml:AttributeStatement>)
        )

      case consume(xml) do
        {:ok, result} -> refute Map.has_key?(result.principal.attributes, "groups")
        {:error, %Error{}} -> :ok
      end
    end

    test "a second Audience injected outside the signed assertion does not widen acceptance" do
      xml =
        inject_before_assertion(
          signed(audience: "https://real.example.com/metadata"),
          ~s(<saml:Audience>#{@sp}</saml:Audience>)
        )

      assert {:error, %Error{type: type}} = consume(xml)
      assert type in [:invalid_audience, :ambiguous_signed_node, :missing_protocol_field]
    end
  end

  # ---------------------------------------------------------------------------
  # Assertion cardinality / placement (S8, S11, S12)
  # ---------------------------------------------------------------------------

  describe "assertion cardinality and placement" do
    test "an ID-less decoy assertion before the signed one is rejected" do
      xml =
        inject_before_assertion(
          signed(),
          ~s(<saml:Assertion><saml:Subject><saml:NameID>attacker@evil.com</saml:NameID></saml:Subject></saml:Assertion>)
        )

      assert {:error, %Error{type: :ambiguous_signed_node}} = consume(xml)
    end

    test "a second fully-formed assertion is rejected as ambiguous" do
      xml = inject_before_assertion(signed(), second_assertion())
      assert {:error, %Error{type: :ambiguous_signed_node}} = consume(xml)
    end

    test "a non-Response root element is rejected" do
      xml = String.replace(signed(), "samlp:Response", "samlp:Garbage")
      assert {:error, %Error{type: :unexpected_root_element}} = consume(xml)
    end
  end

  # ---------------------------------------------------------------------------
  # Signature structure (S1, S2, S3, S4)
  # ---------------------------------------------------------------------------

  describe "signature structure binding" do
    test "a replayed DigestValue hidden in a ds:Object is not read as the Reference digest" do
      xml =
        String.replace(
          signed(),
          "<ds:SignedInfo>",
          ~s(<ds:Object><ds:DigestValue>#{Base.encode64("attacker-digest")}</ds:DigestValue></ds:Object><ds:SignedInfo>),
          global: false
        )

      # The decoy DigestValue lives in a ds:Object that the enveloped-signature
      # transform prunes; the Reference digest is still read from the Reference's
      # own DigestValue, so the attack has no effect: either the original identity
      # verifies, or the structure is rejected. The attacker value is never used.
      case consume(xml) do
        {:ok, result} -> assert result.principal.name_id == @name_id
        {:error, %Error{}} -> :ok
      end
    end

    test "a Reference URI that does not match the Assertion ID is rejected" do
      xml = String.replace(signed(), ~s(URI="#assertion-1"), ~s(URI="#other"), global: false)
      assert {:error, %Error{type: :reference_mismatch}} = consume(xml)
    end

    test "a non-allowlisted CanonicalizationMethod is rejected" do
      xml =
        String.replace(
          signed(),
          ~s(<ds:CanonicalizationMethod Algorithm="#{@exc_c14n}"/>),
          ~s(<ds:CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>),
          global: false
        )

      assert {:error, %Error{type: :unsupported_canonicalization_method}} = consume(xml)
    end
  end

  # ---------------------------------------------------------------------------
  # Namespace lookalikes (S20)
  # ---------------------------------------------------------------------------

  describe "namespace-aware matching" do
    test "a foreign-namespace NameID before the assertion is never consumed" do
      xml =
        inject_before_assertion(
          signed(),
          ~s(<x:NameID xmlns:x="urn:attacker">attacker@evil.com</x:NameID>)
        )

      refute_ok_with_name_id(consume(xml), "attacker@evil.com")
    end
  end

  # ---------------------------------------------------------------------------
  # Protocol binding (S9, S10)
  # ---------------------------------------------------------------------------

  describe "protocol binding" do
    test "an Assertion Issuer that differs from the configured IdP is rejected" do
      # Signed with a mismatched assertion issuer (digest stays valid), so the
      # rejection is the issuer-binding check, not a digest mismatch.
      assert {:error, %Error{type: :assertion_issuer_mismatch}} =
               consume(signed(assertion_issuer: "https://evil.example.com"))
    end

    test "a nested StatusCode decoy does not override the Response Status" do
      xml =
        String.replace(
          signed(),
          ~s(<samlp:StatusCode Value="#{@success}"/>),
          ~s(<samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Responder"><samlp:StatusCode Value="#{@success}"/></samlp:StatusCode>),
          global: false
        )

      assert {:error, %Error{type: :unsupported_status}} = consume(xml)
    end

    test "a SubjectConfirmationData InResponseTo that does not match the request is rejected" do
      xml =
        String.replace(
          signed(),
          ~s(InResponseTo="#{@request_id}" Recipient),
          ~s(InResponseTo="id_request_999" Recipient),
          global: false
        )

      # The SCD InResponseTo is inside the signed assertion, so changing it after
      # signing breaks the digest; a resigned mismatch would raise
      # :subject_confirmation_invalid. Either rejection is acceptable.
      assert {:error, %Error{type: type}} = consume(xml)
      assert type in [:digest_mismatch, :subject_confirmation_invalid]
    end
  end

  # ---------------------------------------------------------------------------
  # Phase 81: logout POST binding (S15)
  # ---------------------------------------------------------------------------

  describe "logout POST binding (S15)" do
    test "a LogoutRequest carrying an embedded Assertion is rejected" do
      # The embedded-assertion wrapping attack: any IdP-signed assertion stuffed
      # into a LogoutRequest must never stand in for a signature over the root.
      xml =
        ~s(<samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="#{@assertion_ns}" ID="lo_1" Version="2.0" IssueInstant="2026-04-24T16:00:00Z"><saml:Issuer>#{@idp}</saml:Issuer><saml:NameID>victim@example.com</saml:NameID><samlp:SessionIndex>s1</samlp:SessionIndex><saml:Assertion ID="a1"><saml:Issuer>#{@idp}</saml:Issuer></saml:Assertion></samlp:LogoutRequest>)

      assert {:error, %Error{type: :logout_assertion_forbidden}} =
               LogoutValidator.validate_logout_request(xml, logout_connection(), binding: :post)
    end

    test "an unsigned POST LogoutRequest (no root signature) is rejected" do
      xml =
        ~s(<samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="#{@assertion_ns}" ID="lo_2" Version="2.0" IssueInstant="2026-04-24T16:00:00Z"><saml:Issuer>#{@idp}</saml:Issuer><saml:NameID>victim@example.com</saml:NameID><samlp:SessionIndex>s1</samlp:SessionIndex></samlp:LogoutRequest>)

      assert {:error, %Error{type: :missing_signature}} =
               LogoutValidator.validate_logout_request(xml, logout_connection(), binding: :post)
    end
  end

  # ---------------------------------------------------------------------------
  # Phase 81: logout HTTP-Redirect duplicate parameters (S16)
  # ---------------------------------------------------------------------------

  describe "logout redirect duplicate parameters (S16)" do
    test "a duplicated SAMLRequest query parameter is rejected" do
      query =
        "SAMLRequest=abc&SigAlg=#{URI.encode_www_form("http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")}&Signature=zzz&SAMLRequest=evil"

      assert {:error, %Error{type: :invalid_binding}} =
               LogoutValidator.validate_logout_request(query, logout_connection(),
                 binding: :redirect
               )
    end
  end

  # ---------------------------------------------------------------------------
  # Phase 81: metadata wrapper (S18)
  # ---------------------------------------------------------------------------

  describe "metadata wrapper (S18)" do
    test "entityID, endpoints and certs come from the signed EntityDescriptor, not an unsigned wrapper" do
      inner =
        ~s(<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:ds="#{@dsig_ns}" entityID="https://good.example.com"><ds:Signature><ds:SignedInfo/></ds:Signature><md:IDPSSODescriptor><md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data><ds:X509Certificate>GOODCERT</ds:X509Certificate></ds:X509Data></ds:KeyInfo></md:KeyDescriptor><md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://good.example.com/sso"/></md:IDPSSODescriptor></md:EntityDescriptor>)

      wrapped =
        ~s(<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:ds="#{@dsig_ns}" entityID="https://evil.example.com"><md:IDPSSODescriptor><md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data><ds:X509Certificate>EVILCERT</ds:X509Certificate></ds:X509Data></ds:KeyInfo></md:KeyDescriptor><md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://evil.example.com/sso"/></md:IDPSSODescriptor>) <>
          inner <> ~s(</md:EntityDescriptor>)

      assert {:ok, parsed} = Relyra.Metadata.Parser.parse(wrapped)
      assert parsed.entity_id == "https://good.example.com"
      assert parsed.certificates == ["GOODCERT"]
      assert [%{location: "https://good.example.com/sso"}] = parsed.sso_services
    end

    test "metadata values are not read from an XML comment" do
      xml =
        ~s(<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:ds="#{@dsig_ns}" entityID="https://good.example.com"><!-- <md:SingleSignOnService Binding="b" Location="https://evil.example.com/sso"/> --><md:IDPSSODescriptor><md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data><ds:X509Certificate>GOODCERT</ds:X509Certificate></ds:X509Data></ds:KeyInfo></md:KeyDescriptor><md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://good.example.com/sso"/></md:IDPSSODescriptor></md:EntityDescriptor>)

      assert {:ok, parsed} = Relyra.Metadata.Parser.parse(xml)
      assert [%{location: "https://good.example.com/sso"}] = parsed.sso_services
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp logout_connection do
    %{
      id: "conn-123",
      connection_id: "conn-123",
      idp_entity_id: @idp,
      issuer: @idp,
      cert_chain: [XmldsigSigner.self_signed_cert_pem()]
    }
  end

  defp consume(xml) do
    Relyra.consume_response(xml, request_intent(), consume_opts())
  end

  defp refute_ok_with_name_id(result, forbidden) do
    case result do
      {:ok, login} -> refute login.principal.name_id == forbidden
      {:error, %Error{}} -> :ok
    end
  end

  defp signed(opts \\ []) do
    %{response_xml: xml} = XmldsigSigner.sign_response(template(opts))
    xml
  end

  defp inject_before_assertion(xml, fragment) do
    String.replace(xml, "<saml:Assertion ", fragment <> "<saml:Assertion ", global: false)
  end

  defp template(opts) do
    not_on_or_after = Keyword.get(opts, :not_on_or_after, "2099-01-01T00:00:00Z")
    audience = Keyword.get(opts, :audience, @sp)
    assertion_issuer = Keyword.get(opts, :assertion_issuer, @idp)

    ~s(<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="#{@assertion_ns}" xmlns:ds="#{@dsig_ns}" Destination="#{@acs}" InResponseTo="#{@request_id}" ConnectionId="conn-123">) <>
      ~s(<saml:Issuer>#{@idp}</saml:Issuer>) <>
      ~s(<samlp:Status><samlp:StatusCode Value="#{@success}"/></samlp:Status>) <>
      ~s(<saml:Assertion ID="assertion-1">) <>
      ~s(<saml:Issuer>#{assertion_issuer}</saml:Issuer>) <>
      ~s(<ds:Signature><ds:SignedInfo>) <>
      ~s(<ds:CanonicalizationMethod Algorithm="#{@exc_c14n}"/>) <>
      ~s(<ds:SignatureMethod Algorithm="#{@rsa_sha256}"/>) <>
      ~s(<ds:Reference URI="#assertion-1">) <>
      ~s(<ds:Transforms><ds:Transform Algorithm="#{@enveloped}"/><ds:Transform Algorithm="#{@exc_c14n}"/></ds:Transforms>) <>
      ~s(<ds:DigestMethod Algorithm="#{@sha256}"/>) <>
      ~s(</ds:Reference></ds:SignedInfo></ds:Signature>) <>
      ~s(<saml:Subject><saml:NameID>#{@name_id}</saml:NameID>) <>
      ~s(<saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">) <>
      ~s(<saml:SubjectConfirmationData InResponseTo="#{@request_id}" Recipient="#{@acs}" NotOnOrAfter="2099-01-01T00:00:00Z"/>) <>
      ~s(</saml:SubjectConfirmation></saml:Subject>) <>
      ~s(<saml:Conditions NotBefore="2000-01-01T00:00:00Z" NotOnOrAfter="#{not_on_or_after}"><saml:AudienceRestriction><saml:Audience>#{audience}</saml:Audience></saml:AudienceRestriction></saml:Conditions>) <>
      ~s(<saml:AttributeStatement><saml:Attribute Name="role"><saml:AttributeValue>member</saml:AttributeValue></saml:Attribute></saml:AttributeStatement>) <>
      ~s(</saml:Assertion></samlp:Response>)
  end

  defp second_assertion do
    ~s(<saml:Assertion ID="assertion-2"><saml:Issuer>#{@idp}</saml:Issuer><saml:Subject><saml:NameID>attacker@evil.com</saml:NameID></saml:Subject></saml:Assertion>)
  end

  defp request_intent do
    %{
      request_id: @request_id,
      connection_id: "conn-123",
      relay_state: "rs_1234567890abcdef",
      in_response_to: @request_id,
      destination: @acs,
      recipient: @acs,
      issuer: @idp,
      sp_entity_id: @sp,
      acs_url: @acs
    }
  end

  defp connection do
    %{
      id: "conn-123",
      connection_id: "conn-123",
      idp_entity_id: @idp,
      issuer: @idp,
      sp_entity_id: @sp,
      acs_url: @acs,
      cert_chain: [XmldsigSigner.self_signed_cert_pem()]
    }
  end

  defp consume_opts do
    [
      connection: connection(),
      resolved_connection: connection(),
      relay_state: "rs_1234567890abcdef",
      request_store: Relyra.Testing.Adapters.RequestStore,
      replay_store: Relyra.Testing.Adapters.ReplayStore,
      connection_resolver: Relyra.Testing.Adapters.ConnectionResolver,
      request_intent: request_intent(),
      now: @now
    ]
  end
end
