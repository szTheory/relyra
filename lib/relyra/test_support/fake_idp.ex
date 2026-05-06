defmodule Relyra.TestSupport.FakeIdP do
  @moduledoc """
  A small in-process SAML response builder for tests.

  The fake IdP does not attempt to model a real admin UI or cryptographic
  signing pipeline. It builds protocol-correct XML that exercises the SP
  pipeline, including the signature and assertion parsing paths used by
  the test suite.
  """

  @prod_build Mix.env() == :prod

  defmodule Builder do
    @moduledoc false
    defstruct [
      :issuer,
      :subject,
      :audience,
      :destination,
      :recipient,
      :in_response_to,
      :name_id,
      :relay_state
    ]
  end

  @default_issuer "https://idp.example.com/metadata"
  @default_subject "user@example.com"
  @default_audience "https://sp.example.com/metadata"
  @default_destination "https://sp.example.com/saml/acs"
  @persistent_term_key {__MODULE__, :rsa_2048_keypair}

  @spec metadata() :: String.t()
  def metadata do
    ensure_not_prod!()
    ensure_keypair!()

    """
    <EntityDescriptor entityID="#{@default_issuer}">
      <IDPSSODescriptor>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://idp.example.com/sso"/>
      </IDPSSODescriptor>
    </EntityDescriptor>
    """
    |> String.trim()
  end

  @spec build_response(keyword()) :: Builder.t()
  def build_response(opts \\ []) when is_list(opts) do
    ensure_not_prod!()
    ensure_keypair!()

    %Builder{
      issuer: Keyword.get(opts, :issuer, @default_issuer),
      subject: Keyword.get(opts, :subject, @default_subject),
      audience: Keyword.get(opts, :audience, @default_audience),
      destination: Keyword.get(opts, :destination, @default_destination),
      recipient: Keyword.get(opts, :recipient, @default_destination),
      in_response_to: Keyword.get(opts, :in_response_to, "id_request_123"),
      name_id: Keyword.get(opts, :name_id, Keyword.get(opts, :subject, @default_subject)),
      relay_state: Keyword.get(opts, :relay_state, "rs_123")
    }
  end

  @spec sign(Builder.t() | keyword(), keyword()) :: String.t()
  def sign(opts, extra_opts \\ [])

  def sign(%Builder{} = builder, opts) do
    ensure_not_prod!()
    ensure_keypair!()
    xml = response_xml(builder, opts)
    Base.encode64(xml, padding: false)
  end

  def sign(opts, extra_opts) when is_list(opts), do: build_response(opts) |> sign(extra_opts)

  @spec keypair() :: term()
  def keypair do
    ensure_not_prod!()
    ensure_keypair!()

    :persistent_term.get(@persistent_term_key)
  end

  defp ensure_keypair! do
    case :persistent_term.get(@persistent_term_key, :missing) do
      :missing ->
        generated = :public_key.generate_key({:rsa, 2048, 65_537})
        :persistent_term.put(@persistent_term_key, generated)
        generated

      keypair ->
        keypair
    end
  end

  defp ensure_not_prod! do
    if @prod_build do
      raise "Relyra.TestSupport.FakeIdP is test-only"
    end
  end

  defp response_xml(%Builder{} = builder, opts) do
    signature_method =
      Keyword.get(opts, :signature_method, "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")

    digest_method = Keyword.get(opts, :digest_method, "http://www.w3.org/2001/04/xmlenc#sha256")
    assertion_id = Keyword.get(opts, :assertion_id, "assertion_123")

    """
    <Response Destination="#{builder.destination}" InResponseTo="#{builder.in_response_to}" ConnectionId="valid">
      <Issuer xmlns="urn:oasis:names:tc:SAML:2.0:assertion">#{builder.issuer}</Issuer>
      <Status><StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></Status>
      <Assertion xmlns="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{assertion_id}">
        <Issuer>#{builder.issuer}</Issuer>
        <Subject>
          <NameID>#{builder.name_id}</NameID>
          <SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
            <SubjectConfirmationData Recipient="#{builder.recipient}" NotOnOrAfter="2099-01-01T00:00:00Z"/>
          </SubjectConfirmation>
        </Subject>
        <Conditions NotBefore="2000-01-01T00:00:00Z" NotOnOrAfter="2099-01-01T00:00:00Z">
          <AudienceRestriction><Audience>#{builder.audience}</Audience></AudienceRestriction>
        </Conditions>
      </Assertion>
      <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
        <SignedInfo>
          <SignatureMethod Algorithm="#{signature_method}"/>
          <Reference URI="##{assertion_id}"><DigestMethod Algorithm="#{digest_method}"/></Reference>
        </SignedInfo>
      </Signature>
    </Response>
    """
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
