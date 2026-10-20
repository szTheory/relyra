defmodule Relyra.Twin.Mint do
  @moduledoc """
  Phase 82 adversarial twin — mints GENUINELY signed base documents plus the
  ground truth of what was signed.

  The twin's whole premise is that the oracle compares a consumed result against
  what the *generator* signed, never against Relyra's own re-parse. So every base
  document carries a `%Relyra.Twin.Mint.Doc{}` whose `truth` map is derived from
  the fields this module put into the template BEFORE handing it to the signer —
  the one source of truth the oracle trusts.

  Four document kinds, each entering through a real public API:

    * `:login`          — `samlp:Response` → `Relyra.consume_response/3`
    * `:logout_redirect`— signed `SAMLRequest` query → `LogoutValidator` redirect
    * `:logout_post`    — enveloped-signed `LogoutRequest` → `LogoutValidator` post
    * `:metadata`       — signed `EntityDescriptor` → `Relyra.Metadata.Parser`

  All signing uses `Relyra.TestSupport.XmldsigSigner` with the one FakeIdP key,
  so the positive control verifies for the RIGHT reason. Test-only.
  """

  alias Relyra.TestSupport.FakeIdP
  alias Relyra.TestSupport.XmldsigSigner

  @assertion_ns "urn:oasis:names:tc:SAML:2.0:assertion"
  @samlp_ns "urn:oasis:names:tc:SAML:2.0:protocol"
  @metadata_ns "urn:oasis:names:tc:SAML:2.0:metadata"
  @dsig_ns "http://www.w3.org/2000/09/xmldsig#"
  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @sha256 "http://www.w3.org/2001/04/xmlenc#sha256"
  @exc_c14n "http://www.w3.org/2001/10/xml-exc-c14n#"
  @enveloped "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
  @bearer "urn:oasis:names:tc:SAML:2.0:cm:bearer"
  @success "urn:oasis:names:tc:SAML:2.0:status:Success"

  @idp "https://idp.example.com/metadata"
  @sp "https://sp.example.com/metadata"
  @acs "https://sp.example.com/saml/acs"
  @request_id "id_request_123"
  @name_id "user@example.com"

  # The instant the oracle evaluates assertions at. Base documents are valid at
  # this instant unless a time-boundary parameter shifts them.
  @now ~U[2026-04-24 16:00:00Z]

  defmodule Doc do
    @moduledoc "A minted twin document: signed payload, cert chain, and signed-field truth."
    @enforce_keys [:kind, :payload, :cert_chain, :truth]
    defstruct [:kind, :payload, :cert_chain, :truth, template: nil, resign: nil]

    @type t :: %__MODULE__{
            kind: :login | :logout_redirect | :logout_post | :metadata,
            payload: String.t(),
            cert_chain: [String.t()],
            truth: map(),
            template: String.t() | nil,
            resign: (String.t() -> String.t()) | nil
          }
  end

  @spec now() :: DateTime.t()
  def now, do: @now

  @spec kinds() :: [atom()]
  def kinds, do: [:login, :logout_redirect, :logout_post, :metadata]

  @doc """
  Mint a genuinely signed base document for `kind`.

  `opts`:
    * `:name_id`, `:audience`, `:assertion_id` — login field overrides
    * `:not_on_or_after`, `:not_before` — assertion time window (defaults valid at `now/0`)
    * `:id` — message/descriptor ID (defaults unique so replay never trips)
  """
  @spec mint(atom(), keyword()) :: Doc.t()
  def mint(kind, opts \\ [])

  def mint(:login, opts) do
    name_id = Keyword.get(opts, :name_id, @name_id)
    audience = Keyword.get(opts, :audience, @sp)
    assertion_id = Keyword.get(opts, :assertion_id, "assertion-#{unique()}")
    not_on_or_after = Keyword.get(opts, :not_on_or_after, "2099-01-01T00:00:00Z")
    not_before = Keyword.get(opts, :not_before, "2000-01-01T00:00:00Z")

    template =
      login_template(
        name_id: name_id,
        audience: audience,
        assertion_id: assertion_id,
        not_before: not_before,
        not_on_or_after: not_on_or_after
      )

    %{response_xml: signed, cert_chain: chain} = XmldsigSigner.sign_response(template)

    %Doc{
      kind: :login,
      payload: signed,
      cert_chain: chain,
      truth: %{name_id: name_id, attributes: %{"role" => ["member"]}, audience: audience},
      template: template,
      resign: fn tmpl -> XmldsigSigner.sign_response(tmpl).response_xml end
    }
  end

  def mint(:logout_redirect, opts) do
    id = Keyword.get(opts, :id, "req_#{unique()}")
    name_id = Keyword.get(opts, :name_id, @name_id)
    session_index = "session_#{unique()}"

    xml = logout_request_xml(id, name_id, session_index)
    query = build_signed_redirect_query(xml, "SAMLRequest")

    %Doc{
      kind: :logout_redirect,
      payload: query,
      cert_chain: [FakeIdP.self_signed_cert_pem()],
      truth: %{id: id, name_id: name_id, session_index: session_index, issuer: @idp},
      template: xml,
      resign: fn inner -> build_signed_redirect_query(inner, "SAMLRequest") end
    }
  end

  def mint(:logout_post, opts) do
    id = Keyword.get(opts, :id, "req_#{unique()}")
    name_id = Keyword.get(opts, :name_id, @name_id)
    session_index = "session_#{unique()}"

    template = logout_post_template(id, name_id, session_index)
    %{xml: signed, cert_chain: chain} = XmldsigSigner.sign_enveloped(template)

    %Doc{
      kind: :logout_post,
      payload: signed,
      cert_chain: chain,
      truth: %{id: id, name_id: name_id, session_index: session_index, issuer: @idp},
      template: template,
      resign: fn tmpl -> XmldsigSigner.sign_enveloped(tmpl).xml end
    }
  end

  def mint(:metadata, opts) do
    entity_id = Keyword.get(opts, :entity_id, @idp)
    descriptor_id = Keyword.get(opts, :id, "md_#{unique()}")
    sso = Keyword.get(opts, :sso, "https://idp.example.com/sso")

    template = metadata_template(descriptor_id, entity_id, sso)
    %{xml: signed, cert_chain: chain} = XmldsigSigner.sign_enveloped(template)

    %Doc{
      kind: :metadata,
      payload: signed,
      cert_chain: chain,
      truth: %{entity_id: entity_id, sso: sso},
      template: template,
      resign: fn tmpl -> XmldsigSigner.sign_enveloped(tmpl).xml end
    }
  end

  # ---------------------------------------------------------------------------
  # Templates
  # ---------------------------------------------------------------------------

  defp login_template(f) do
    ~s(<samlp:Response xmlns:samlp="#{@samlp_ns}" xmlns:saml="#{@assertion_ns}" xmlns:ds="#{@dsig_ns}" Destination="#{@acs}" InResponseTo="#{@request_id}" ConnectionId="conn-123">) <>
      ~s(<saml:Issuer>#{@idp}</saml:Issuer>) <>
      ~s(<samlp:Status><samlp:StatusCode Value="#{@success}"/></samlp:Status>) <>
      ~s(<saml:Assertion ID="#{f[:assertion_id]}">) <>
      ~s(<saml:Issuer>#{@idp}</saml:Issuer>) <>
      ~s(<ds:Signature><ds:SignedInfo>) <>
      ~s(<ds:CanonicalizationMethod Algorithm="#{@exc_c14n}"/>) <>
      ~s(<ds:SignatureMethod Algorithm="#{@rsa_sha256}"/>) <>
      ~s(<ds:Reference URI="##{f[:assertion_id]}">) <>
      ~s(<ds:Transforms><ds:Transform Algorithm="#{@enveloped}"/><ds:Transform Algorithm="#{@exc_c14n}"/></ds:Transforms>) <>
      ~s(<ds:DigestMethod Algorithm="#{@sha256}"/>) <>
      ~s(</ds:Reference></ds:SignedInfo></ds:Signature>) <>
      ~s(<saml:Subject><saml:NameID>#{f[:name_id]}</saml:NameID>) <>
      ~s(<saml:SubjectConfirmation Method="#{@bearer}">) <>
      ~s(<saml:SubjectConfirmationData InResponseTo="#{@request_id}" Recipient="#{@acs}" NotOnOrAfter="2099-01-01T00:00:00Z"/>) <>
      ~s(</saml:SubjectConfirmation></saml:Subject>) <>
      ~s(<saml:Conditions NotBefore="#{f[:not_before]}" NotOnOrAfter="#{f[:not_on_or_after]}"><saml:AudienceRestriction><saml:Audience>#{f[:audience]}</saml:Audience></saml:AudienceRestriction></saml:Conditions>) <>
      ~s(<saml:AttributeStatement><saml:Attribute Name="role"><saml:AttributeValue>member</saml:AttributeValue></saml:Attribute></saml:AttributeStatement>) <>
      ~s(</saml:Assertion></samlp:Response>)
  end

  defp logout_request_xml(id, name_id, session_index) do
    ~s(<samlp:LogoutRequest xmlns:samlp="#{@samlp_ns}" xmlns:saml="#{@assertion_ns}" ID="#{id}" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">) <>
      ~s(<saml:Issuer>#{@idp}</saml:Issuer>) <>
      ~s(<saml:NameID>#{name_id}</saml:NameID>) <>
      ~s(<samlp:SessionIndex>#{session_index}</samlp:SessionIndex>) <>
      ~s(</samlp:LogoutRequest>)
  end

  # Enveloped-signed LogoutRequest: the ds:Signature is a direct child of the
  # root, Reference URI = root ID. XmldsigSigner.sign_enveloped/1 fills the
  # DigestValue / SignatureValue.
  defp logout_post_template(id, name_id, session_index) do
    ~s(<samlp:LogoutRequest xmlns:samlp="#{@samlp_ns}" xmlns:saml="#{@assertion_ns}" xmlns:ds="#{@dsig_ns}" ID="#{id}" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">) <>
      ~s(<saml:Issuer>#{@idp}</saml:Issuer>) <>
      ~s(<ds:Signature><ds:SignedInfo>) <>
      ~s(<ds:CanonicalizationMethod Algorithm="#{@exc_c14n}"/>) <>
      ~s(<ds:SignatureMethod Algorithm="#{@rsa_sha256}"/>) <>
      ~s(<ds:Reference URI="##{id}">) <>
      ~s(<ds:Transforms><ds:Transform Algorithm="#{@enveloped}"/><ds:Transform Algorithm="#{@exc_c14n}"/></ds:Transforms>) <>
      ~s(<ds:DigestMethod Algorithm="#{@sha256}"/>) <>
      ~s(</ds:Reference></ds:SignedInfo></ds:Signature>) <>
      ~s(<saml:NameID>#{name_id}</saml:NameID>) <>
      ~s(<samlp:SessionIndex>#{session_index}</samlp:SessionIndex>) <>
      ~s(</samlp:LogoutRequest>)
  end

  defp metadata_template(id, entity_id, sso) do
    cert = der_body(FakeIdP.self_signed_cert_pem())

    ~s(<md:EntityDescriptor xmlns:md="#{@metadata_ns}" xmlns:ds="#{@dsig_ns}" ID="#{id}" entityID="#{entity_id}">) <>
      ~s(<ds:Signature><ds:SignedInfo>) <>
      ~s(<ds:CanonicalizationMethod Algorithm="#{@exc_c14n}"/>) <>
      ~s(<ds:SignatureMethod Algorithm="#{@rsa_sha256}"/>) <>
      ~s(<ds:Reference URI="##{id}">) <>
      ~s(<ds:Transforms><ds:Transform Algorithm="#{@enveloped}"/><ds:Transform Algorithm="#{@exc_c14n}"/></ds:Transforms>) <>
      ~s(<ds:DigestMethod Algorithm="#{@sha256}"/>) <>
      ~s(</ds:Reference></ds:SignedInfo></ds:Signature>) <>
      ~s(<md:IDPSSODescriptor protocolSupportEnumeration="#{@samlp_ns}">) <>
      ~s(<md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data><ds:X509Certificate>#{cert}</ds:X509Certificate></ds:X509Data></ds:KeyInfo></md:KeyDescriptor>) <>
      ~s(<md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="#{sso}"/>) <>
      ~s(</md:IDPSSODescriptor></md:EntityDescriptor>)
  end

  # ---------------------------------------------------------------------------
  # Signing + encoding helpers
  # ---------------------------------------------------------------------------

  defp build_signed_redirect_query(xml, param_name) do
    z = :zlib.open()
    :zlib.deflateInit(z, :default, :deflated, -15, 8, :default)
    deflated = z |> :zlib.deflate(xml, :finish) |> IO.iodata_to_binary()
    :zlib.close(z)

    payload_b64 = deflated |> Base.encode64() |> URI.encode_www_form()
    sig_alg_enc = URI.encode_www_form(@rsa_sha256)
    raw_signed_query = "#{param_name}=#{payload_b64}&SigAlg=#{sig_alg_enc}"

    signature_b64 =
      raw_signed_query
      |> then(&:public_key.sign(&1, :sha256, FakeIdP.keypair()))
      |> Base.encode64()
      |> URI.encode_www_form()

    "#{raw_signed_query}&Signature=#{signature_b64}"
  end

  defp der_body(pem) do
    pem
    |> String.split("\n")
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "-----")))
    |> Enum.join()
  end

  defp unique, do: System.unique_integer([:positive])
end
