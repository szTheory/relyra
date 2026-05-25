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

  # XML-Enc algorithm URIs. The first two are the proven, accepted recipe
  # (mirror xml_enc_test.exs:7-10); the latter two are blocked variants the
  # Plan 04 adversarial fixtures feed via encrypt/3 opts to prove fail-closed.
  @rsa_oaep_uri "http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"
  @aes256_gcm_uri "http://www.w3.org/2001/04/xmlenc#aes256-gcm"
  @rsa_pkcs1_uri "http://www.w3.org/2001/04/xmlenc#rsa-1_5"
  @aes256_cbc_uri "http://www.w3.org/2001/04/xmlenc#aes256-cbc"

  @spec metadata() :: String.t()
  def metadata do
    ensure_not_prod!()

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
    %{response_xml: signed_xml} = Relyra.TestSupport.XmldsigSigner.sign_response(xml)
    Base.encode64(signed_xml, padding: false)
  end

  def sign(opts, extra_opts) when is_list(opts), do: build_response(opts) |> sign(extra_opts)

  @doc """
  Wrap a plaintext (typically a genuinely-signed `<Assertion>` fragment) into an
  `<EncryptedAssertion>` envelope using RSA-OAEP key transport + AES-256-GCM
  content encryption against the SP **public** key, mirroring how `sign/2` is the
  single canonical signer (D-08).

  This is the single canonical encrypted-assertion generator — every ENC-01
  adversarial fixture (Plan 04) wraps its plaintext through here so a divergent
  per-test recipe can never mask a real canonicalization or auth-tag bug
  (Pitfall 1 / T-34-04).

  The CipherValue layout is exactly `Base.encode64(iv <> ciphertext <> auth_tag)`
  with a 12-byte IV and a 16-byte GCM tag — the `IV(12) || CT || Tag(16)` layout
  `Relyra.Security.XMLEnc.split_cipher_value/1` round-trips (Pitfall 4 /
  T-34-05). Feeding the output to `XMLEnc.decrypt/3` with the matching SP private
  key resolver returns `{:ok, plaintext}` (byte identity).

  Only the SP **public** key `{:RSAPublicKey, n, e}` is used here; no private key
  material touches the encrypt path (T-34-06). Derive `sp_pub_key` from
  `keypair/0` the way `xml_enc_test.exs:13-15` does.
  """
  @spec encrypt(binary(), :public_key.rsa_public_key()) :: String.t()
  def encrypt(plaintext, sp_pub_key) when is_binary(plaintext) do
    encrypt(plaintext, sp_pub_key, [])
  end

  @doc """
  The XML-Enc algorithm URIs the encrypt path knows about, as a map.

  Plan 04 adversarial fixtures read the blocked variants (`:rsa_pkcs1` and
  `:aes256_cbc`) from here so the URI strings live in exactly one place — the
  single canonical generator — rather than being re-typed per fixture.
  """
  @spec enc_algorithm_uris() :: %{
          rsa_oaep: String.t(),
          aes256_gcm: String.t(),
          rsa_pkcs1: String.t(),
          aes256_cbc: String.t()
        }
  def enc_algorithm_uris do
    %{
      rsa_oaep: @rsa_oaep_uri,
      aes256_gcm: @aes256_gcm_uri,
      rsa_pkcs1: @rsa_pkcs1_uri,
      aes256_cbc: @aes256_cbc_uri
    }
  end

  @doc """
  Adversarial-aware variant of `encrypt/2`.

  Options let Plan 04 fixtures deliberately diverge from the accepted recipe so
  the SP pipeline can be proven to fail closed:

    * `:key_transport_uri` — algorithm URI advertised for the wrapped CEK
      (default `rsa-oaep-mgf1p`; `rsa-1_5` for the blocked-PKCS1v1.5 fixture).
    * `:key_padding` — the `:rsa_padding` atom actually used to wrap the CEK
      (default `:rsa_pkcs1_oaep_padding`).
    * `:content_uri` — algorithm URI advertised for content encryption (default
      `aes256-gcm`; `aes256-cbc` for the blocked-CBC fixture).
    * `:tag_length` — GCM auth-tag byte length (default 16; e.g. 15 for the
      truncated-tag fixture).
    * `:iv` — explicit 12-byte IV (default random).
    * `:cipher_value_b64` — override the content CipherValue text verbatim (e.g.
      malformed base64 for the bad-ciphertext fixture); skips content encryption.
  """
  @spec encrypt(binary(), :public_key.rsa_public_key(), keyword()) :: String.t()
  def encrypt(plaintext, sp_pub_key, opts) when is_binary(plaintext) and is_list(opts) do
    ensure_not_prod!()
    ensure_keypair!()

    key_transport_uri = Keyword.get(opts, :key_transport_uri, @rsa_oaep_uri)
    key_padding = Keyword.get(opts, :key_padding, :rsa_pkcs1_oaep_padding)
    content_uri = Keyword.get(opts, :content_uri, @aes256_gcm_uri)
    tag_length = Keyword.get(opts, :tag_length, 16)

    # RSA-OAEP-wrap a fresh 256-bit CEK with the SP public key
    # (xml_enc_test.exs:40-45).
    cek = :crypto.strong_rand_bytes(32)
    enc_key_bytes = :public_key.encrypt_public(cek, sp_pub_key, [{:rsa_padding, key_padding}])
    enc_key_b64 = Base.encode64(enc_key_bytes)

    # AES-256-GCM-encrypt the plaintext, emitting IV(12) || CT || Tag(N)
    # (xml_enc_test.exs:48-53). An explicit override is honored for the
    # malformed-ciphertext fixture.
    cipher_value_b64 =
      case Keyword.fetch(opts, :cipher_value_b64) do
        {:ok, override} when is_binary(override) ->
          override

        :error ->
          iv = Keyword.get(opts, :iv, :crypto.strong_rand_bytes(12))

          {ciphertext, auth_tag} =
            :crypto.crypto_one_time_aead(:aes_256_gcm, cek, iv, plaintext, <<>>, tag_length, true)

          Base.encode64(iv <> ciphertext <> auth_tag)
      end

    build_encrypted_assertion(key_transport_uri, content_uri, enc_key_b64, cipher_value_b64)
  end

  @doc """
  Build a complete SAML `<Response>` binary carrying an `<EncryptedAssertion>` in
  place of a cleartext `<Assertion>` — the shape `ValidationPipeline.run/4` will
  consume (Plan 04).

  The inner `<Assertion>` is genuinely signed FIRST via the canonical
  `XmldsigSigner` path, THEN encrypted, so the post-decrypt bytes carry the real
  `DigestValue` / `SignatureValue` the verifier checks (RESEARCH note line 381).
  The encrypted `<Assertion>` (and its sibling `<Signature>`) carry their own
  `xmlns="urn:oasis:names:tc:SAML:2.0:assertion"` so canonical bytes survive the
  decrypt → re-parse → splice (Pitfall 1 / T-34-04).

  `response_opts` are forwarded to the signer (`:issuer`, `:name_id`,
  `:assertion_id`, `:destination`, …); `encrypt_opts` are forwarded to
  `encrypt/3` (the adversarial overrides).
  """
  @spec encrypted_response(keyword(), keyword()) :: String.t()
  def encrypted_response(response_opts \\ [], encrypt_opts \\ [])
      when is_list(response_opts) and is_list(encrypt_opts) do
    ensure_not_prod!()
    ensure_keypair!()

    signed_assertion = signed_assertion_fragment(response_opts)
    encrypted_assertion = encrypt(signed_assertion, sp_public_key(), encrypt_opts)

    issuer = Keyword.get(response_opts, :issuer, @default_issuer)
    destination = Keyword.get(response_opts, :destination, @default_destination)
    in_response_to = Keyword.get(response_opts, :in_response_to, "id_request_123")
    status = Keyword.get(response_opts, :status, "urn:oasis:names:tc:SAML:2.0:status:Success")

    """
    <Response Destination="#{destination}" InResponseTo="#{in_response_to}" ConnectionId="valid">
      <Issuer xmlns="urn:oasis:names:tc:SAML:2.0:assertion">#{issuer}</Issuer>
      <Status><StatusCode Value="#{status}"/></Status>
      #{encrypted_assertion}
    </Response>
    """
    |> String.trim()
  end

  @doc """
  The self-signed certificate PEM (a single-element cert chain) callers must
  trust to accept a `FakeIdP.sign/2`-produced Response. Derived from
  `keypair/0` via the promoted genuine signer (D-03), so configuring a
  connection's `cert_chain` / `idp_certificates` with this PEM lets the
  verifier accept FakeIdP's real signatures.
  """
  @spec self_signed_cert_pem() :: String.t()
  defdelegate self_signed_cert_pem(), to: Relyra.TestSupport.XmldsigSigner

  @spec keypair() :: term()
  def keypair do
    ensure_not_prod!()
    ensure_keypair!()

    :persistent_term.get(@persistent_term_key)
  end

  # The accepted EncryptedAssertion envelope (promoted verbatim from
  # xml_enc_test.exs:28-33) — content EncryptionMethod, the RSA-wrapped CEK under
  # ds:KeyInfo → xenc:EncryptedKey, then the content CipherData. The shape
  # XMLEnc.parse_enc_fields/1 walks.
  defp build_encrypted_assertion(key_transport_uri, content_uri, enc_key_b64, cipher_value_b64) do
    """
    <EncryptedAssertion xmlns:xenc="http://www.w3.org/2001/04/xmlenc#" xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><xenc:EncryptedData><xenc:EncryptionMethod Algorithm="#{content_uri}"/><ds:KeyInfo><xenc:EncryptedKey><xenc:EncryptionMethod Algorithm="#{key_transport_uri}"/><xenc:CipherData><xenc:CipherValue>#{enc_key_b64}</xenc:CipherValue></xenc:CipherData></xenc:EncryptedKey></ds:KeyInfo><xenc:CipherData><xenc:CipherValue>#{cipher_value_b64}</xenc:CipherValue></xenc:CipherData></xenc:EncryptedData></EncryptedAssertion>
    """
    |> String.trim()
  end

  # The SP public key {:RSAPublicKey, n, e} derived from keypair/0 — the encrypt
  # path NEVER touches the private key (T-34-06). Same derivation as
  # xml_enc_test.exs:13-15.
  defp sp_public_key do
    {:RSAPrivateKey, _, n, e, _, _, _, _, _, _, _} = keypair()
    {:RSAPublicKey, n, e}
  end

  # Genuinely sign a Response via the canonical signer, then extract the signed
  # <Assertion> together with its sibling <Signature> for wrapping into an
  # <EncryptedAssertion>. The Signature stays a sibling of the Assertion — the
  # shape PureBeam.signed_candidates/1 pairs by Assertion ID + the bound
  # ds:Signature (find_first(root, "Signature")).
  #
  # CRITICAL (T-34-04): the signer emits the Assertion ALREADY carrying its own
  # default namespace (`assertion_namespace: true`), so the genuine DigestValue is
  # computed over the NAMESPACED Assertion. The extracted bytes are spliced back
  # into a Response and re-canonicalized WITH that namespace in scope; computing
  # the digest over the same namespaced bytes is what makes the post-decrypt
  # verification succeed. We must NOT re-declare the namespace AFTER signing — that
  # would change the canonical bytes the verifier recomputes and break the digest
  # (the exact bug fixed in Plan 04).
  defp signed_assertion_fragment(response_opts) do
    signer_opts = Keyword.put(response_opts, :assertion_namespace, true)

    %{response_xml: signed_xml} = Relyra.TestSupport.XmldsigSigner.signed_response(signer_opts)

    assertion = extract_element(signed_xml, "Assertion")
    signature = extract_element(signed_xml, "Signature")

    assertion <> signature
  end

  # Extract the first <Local ...>...</Local> element (verbatim bytes) from xml.
  # Raises if the element is absent so a malformed fixture fails loudly.
  defp extract_element(xml, local) do
    case Regex.run(~r/<#{local}\b.*?<\/#{local}>/s, xml) do
      [element] ->
        element

      _ ->
        raise ArgumentError,
              "FakeIdP.signed_assertion_fragment/1: no <#{local}> in signed Response"
    end
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
          <CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
          <SignatureMethod Algorithm="#{signature_method}"/>
          <Reference URI="##{assertion_id}"><DigestMethod Algorithm="#{digest_method}"/></Reference>
        </SignedInfo>
      </Signature>
    </Response>
    """
    |> String.trim()
  end
end
