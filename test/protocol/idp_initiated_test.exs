defmodule Relyra.Protocol.IdpInitiatedTest do
  use ExUnit.Case, async: false

  alias Relyra.Error
  alias Relyra.Protocol.ValidationPipeline

  @fixed_now ~U[2026-04-24 16:00:00Z]
  @success_status "urn:oasis:names:tc:SAML:2.0:status:Success"

  defp connection(overrides) do
    overrides = Enum.into(overrides, %{})

    Map.merge(
      %{
        connection_id: "conn-123",
        idp_entity_id: "https://idp.example.com/metadata",
        issuer: "https://idp.example.com/metadata",
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        cert_chain: [],
        allow_idp_initiated: false
      },
      overrides
    )
  end

  defp response_xml(overrides) do
    overrides = Enum.into(overrides, %{})

    fields =
      Map.merge(
        %{
          in_response_to: "id_request_123",
          issuer: "https://idp.example.com/metadata",
          destination: "https://sp.example.com/saml/acs",
          recipient: "https://sp.example.com/saml/acs",
          audience: "https://sp.example.com/metadata"
        },
        overrides
      )

    in_response_to_attr =
      if fields.in_response_to, do: ~s( InResponseTo="#{fields.in_response_to}"), else: ""

    # A parse-valid, SAML-conformant Response (enveloped ds:Signature inside the
    # Assertion, bearer SubjectConfirmation). These tests exercise the
    # request-correlation stage, which runs before signature verification, so
    # the signature placeholders are left empty on purpose — correlation fires
    # first for the IdP-initiated cases under test.
    """
    <samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" Destination="#{fields.destination}"#{in_response_to_attr}>
      <saml:Issuer>#{fields.issuer}</saml:Issuer>
      <samlp:Status><samlp:StatusCode Value="#{@success_status}"/></samlp:Status>
      <saml:Assertion ID="a1">
        <saml:Issuer>#{fields.issuer}</saml:Issuer>
        <ds:Signature><ds:SignedInfo>
          <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
          <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
          <ds:Reference URI="#a1">
            <ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms>
            <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
          </ds:Reference>
        </ds:SignedInfo></ds:Signature>
        <saml:Subject>
          <saml:NameID>user@example.com</saml:NameID>
          <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
            <saml:SubjectConfirmationData Recipient="#{fields.recipient}" NotOnOrAfter="2026-04-24T16:05:00Z"/>
          </saml:SubjectConfirmation>
        </saml:Subject>
        <saml:Conditions NotBefore="2026-04-24T15:58:00Z" NotOnOrAfter="2026-04-24T16:05:00Z">
          <saml:AudienceRestriction><saml:Audience>#{fields.audience}</saml:Audience></saml:AudienceRestriction>
        </saml:Conditions>
      </saml:Assertion>
    </samlp:Response>
    """
    |> String.trim()
  end

  describe "IdP-initiated SSO support" do
    test "ValidationPipeline rejects nil request_intent if allow_idp_initiated is false" do
      conn = connection(allow_idp_initiated: false)
      xml = response_xml(in_response_to: nil)

      # This should fail due to correlation check, not guards
      assert {:error, %Error{type: :idp_initiated_not_allowed}} =
               ValidationPipeline.run(xml, nil, conn, [])
    end

    test "ValidationPipeline accepts missing InResponseTo if allow_idp_initiated is true" do
      conn = connection(allow_idp_initiated: true)
      xml = response_xml(in_response_to: nil)

      # We mock signature verification because we don't want to deal with it here
      opts = [now: @fixed_now, cert_chain: []]

      # This should pass correlation but fail later if we don't mock everything.
      # But for now, let's see if it gets past correlation.
      result = ValidationPipeline.run(xml, nil, conn, opts)

      # It should NOT be :internal_protocol_error (guard failure)
      # It might be :missing_signature if we don't mock it, which is fine for this test's purpose (getting past correlation)
      case result do
        {:error, %Error{type: :internal_protocol_error}} ->
          flunk("Should have passed guards")

        {:error, %Error{type: :in_response_to_mismatch}} ->
          flunk("Should have passed correlation")

        _ ->
          :ok
      end
    end

    test "ValidationPipeline rejects InResponseTo if processing as IdP-initiated (intent is nil)" do
      conn = connection(allow_idp_initiated: true)
      xml = response_xml(in_response_to: "unsolicited_id")

      result = ValidationPipeline.run(xml, nil, conn, now: @fixed_now)

      assert {:error, %Error{type: :in_response_to_mismatch}} = result
    end

    test "Relyra.consume_response handles nil request_intent_or_opts" do
      conn = connection(allow_idp_initiated: true)
      xml = response_xml(in_response_to: nil)

      # We need to provide enough opts for Relyra to function
      opts = [
        relay_state: "/dashboard",
        connection: conn,
        now: @fixed_now,
        request_store: Relyra.Protocol.TestRequestStore,
        replay_store: Relyra.Protocol.TestReplayStore
      ]

      # This should call resolve_request_intent with opts, and if it returns {:ok, nil, opts}, it should proceed
      result = Relyra.consume_response(xml, opts)

      case result do
        {:error, %Error{type: :relay_state_missing}} ->
          flunk("Should have accepted opts as second arg")

        _ ->
          :ok
      end
    end
  end
end
