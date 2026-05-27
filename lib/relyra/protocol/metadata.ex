defmodule Relyra.Protocol.Metadata do
  @moduledoc false

  # XMLEnc accept-list URIs advertised in the encryption KeyDescriptor's
  # <md:EncryptionMethod>. These MUST match the decryptor's accept-list
  # (lib/relyra/security/xml_enc.ex) — the plain xmlenc# forms only, NOT the
  # later-spec menu. Advertising an algorithm the SP hard-rejects (PKCS1v1.5,
  # CBC, or a later-spec OAEP URI) would invite the IdP to encrypt with bytes
  # the SP can never decrypt (T-34-03).
  @encryption_method_uris [
    "http://www.w3.org/2001/04/xmlenc#aes256-gcm",
    "http://www.w3.org/2001/04/xmlenc#aes128-gcm",
    "http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"
  ]

  @spec build_sp_metadata(map(), keyword()) :: binary()
  def build_sp_metadata(connection, _opts \\ []) do
    issuer = Map.get(connection, :sp_entity_id) || Map.get(connection, :issuer)
    acs_url = Map.get(connection, :acs_url)
    sign_authn_requests = Map.get(connection, :sign_authn_requests, false) == true

    # T-34-01: PUBLIC certs only — read :sp_signing_cert_pem / :sp_encryption_cert_pem.
    # The SP private key is the KeyResolver's concern, never metadata's; this builder
    # must not source any private key material.
    signing_cert_b64 = cert_body(Application.get_env(:relyra, :sp_signing_cert_pem))
    encryption_cert_b64 = cert_body(Application.get_env(:relyra, :sp_encryption_cert_pem))
    signing_descriptor = signing_key_descriptor(sign_authn_requests, signing_cert_b64)
    authn_requests_attr = authn_requests_signed_attr(sign_authn_requests)

    # T-34-02: schema-valid SPSSODescriptor child order — KeyDescriptor [0..*] BEFORE
    # AssertionConsumerService [1..*]; signing descriptor before encryption descriptor;
    # KeyInfo before EncryptionMethod inside each KeyDescriptor.
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" entityID="#{issuer}">
      <md:SPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol"#{authn_requests_attr}>
    #{signing_descriptor}
        <md:KeyDescriptor use="encryption">
          <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:X509Data><ds:X509Certificate>#{encryption_cert_b64}</ds:X509Certificate></ds:X509Data></ds:KeyInfo>
    #{encryption_methods()}
        </md:KeyDescriptor>
        <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="#{acs_url}" index="1" isDefault="true"/>
      </md:SPSSODescriptor>
    </md:EntityDescriptor>
    """
    |> String.trim()
  end

  # PEM -> DER -> base64 (the <ds:X509Certificate> body: base64-of-DER, no PEM armor,
  # no embedded newlines). Mirrors signature.ex:288-289. Nil-safe: absent config
  # yields an empty body string so the metadata XML stays well-formed (never raises).
  defp cert_body(pem) when is_binary(pem) do
    case :public_key.pem_decode(pem) do
      [entry | _] ->
        case elem(entry, 1) do
          der when is_binary(der) -> Base.encode64(der)
          _ -> ""
        end

      _ ->
        ""
    end
  rescue
    _ -> ""
  end

  defp cert_body(_), do: ""

  defp signing_key_descriptor(true, signing_cert_b64) do
    """
        <md:KeyDescriptor use="signing">
          <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:X509Data><ds:X509Certificate>#{signing_cert_b64}</ds:X509Certificate></ds:X509Data></ds:KeyInfo>
        </md:KeyDescriptor>
    """
    |> String.trim_trailing()
  end

  defp signing_key_descriptor(false, _signing_cert_b64), do: ""

  defp authn_requests_signed_attr(true), do: ~s( AuthnRequestsSigned="true")
  defp authn_requests_signed_attr(false), do: ""

  defp encryption_methods do
    @encryption_method_uris
    |> Enum.map(fn uri -> "      <md:EncryptionMethod Algorithm=\"#{uri}\"/>" end)
    |> Enum.join("\n")
  end
end
