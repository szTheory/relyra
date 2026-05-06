defmodule Relyra.MetadataTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.ConnectionResolver.Ecto, as: EctoResolver
  alias Relyra.Ecto.{Certificate, Connection}
  alias Relyra.Metadata
  alias Relyra.Metadata.Import

  @repo Relyra.TestSupport.EctoTestRepo

  @cert_one_pem """
  -----BEGIN CERTIFICATE-----
  MIIDEzCCAfugAwIBAgIUL4tsJefr6QE1KzzBr+YBxOfBqd8wDQYJKoZIhvcNAQEL
  BQAwGTEXMBUGA1UEAwwOcGhhc2UxMC10ZXN0LTEwHhcNMjYwNTA1MjAxODUwWhcN
  MjYwNjA0MjAxODUwWjAZMRcwFQYDVQQDDA5waGFzZTEwLXRlc3QtMTCCASIwDQYJ
  KoZIhvcNAQEBBQADggEPADCCAQoCggEBAM1cwb/hjGGAKdoFzQ3ZumZ5w2EwisU6
  JrZ1tsLZvzuBFDnQwSMIlEBnOZcxVb6gBS1yKytU04m3w8Yuz+poJIHxURndwOtD
  As4ogUEriv8Q9snb9dvjhJMUHzt8aFiG/dF8TyCbYqpyeElV6dA+gzACm570t23Z
  WFv49ucgekmOxomW6EbsuNwD3eH9eU5vLxXjXp/pdZfWHB37yuZbsawYPbZKlmlM
  Ua5iYt+cLqODJJviF9p9XqjnzgEN9MC8vE2LxSHK7sMdWpjEwVRVuIxcNqseewcY
  IFx0Qp++PrSLkkDhkH4rpkZGOCbrnkxhEwctxyc8F+WbYwuaB3Y20EUCAwEAAaNT
  MFEwHQYDVR0OBBYEFJqT5ohQRMzc7ciLx25XzHFHrQVtMB8GA1UdIwQYMBaAFJqT
  5ohQRMzc7ciLx25XzHFHrQVtMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEL
  BQADggEBAGRp3+eeSCL/A4uKAV8zh+uYiQurc0ouQr5gBzihRrHMDj1Qf6T9wJgV
  o70LKpcuGpmrxH4Bqdf7W3s9snC+g+Cg2JK2Y2akMhjJ0W/jeiCc4SYswEbx3FK3
  oIfM63NPDsxWrFCAVQCK3k2/a2Go2FPZ8EjBTkRKsVGADK7ufYUcoyqEOhdK6+Z6
  oPE1fBjvoNomETj50YKOkEj2tAeSarR1vNLPihuV/pGsxOAx9QGnC2Vxn1LfU+G1
  sBJ8LDs/OhHf/H1rJjmgqE85KV3ACm0UV4YYW8XXmRRUQCV7nFG6cS+Gnks2bTwv
  7OBCV0aYyNmkxkWbGiyNRtwu83BRVdc=
  -----END CERTIFICATE-----
  """

  @cert_two_pem """
  -----BEGIN CERTIFICATE-----
  MIIDEzCCAfugAwIBAgIUXVtzU8ffQDHWYvtv2Y0kLqwKqtYwDQYJKoZIhvcNAQEL
  BQAwGTEXMBUGA1UEAwwOcGhhc2UxMC10ZXN0LTIwHhcNMjYwNTA1MjAxODUwWhcN
  MjYwODAzMjAxODUwWjAZMRcwFQYDVQQDDA5waGFzZTEwLXRlc3QtMjCCASIwDQYJ
  KoZIhvcNAQEBBQADggEPADCCAQoCggEBANtAySPCQWOd+oNvfnfkLYeyzeoSOuHP
  K5K6Jsbj7JobGvAO6uSN1qlkOItclJH4LFK6hQXLeqnSbuuITiCg8IREElH5Z2Dj
  YPI/H9WRc+xjfyOxaQS3Q1Lm0Tm/jCgTbB6FPTfr2/EnYNpgiEOP+iIg+e++RWqi
  Zn9ub3/Rfg37eHRERhxwKxC7HYXukwIVf5vj3nasyR6LLREBpqKIYt2Hvc75h/Qf
  0ULknFOc+wa1AE5hZs6gckCph8LcLR8BYnwHWcEPr23o4QBncKSga00xdhX+TUYK
  BSXDRpz92OIfxTn+ig5xyaeYvenUtKVXn9TPC62w3ipM+tg2R9i/sY0CAwEAAaNT
  MFEwHQYDVR0OBBYEFMlYhziYSpJJxzY6fzciZDK9XRrUMB8GA1UdIwQYMBaAFMlY
  hziYSpJJxzY6fzciZDK9XRrUMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEL
  BQADggEBAGmRgs4UZFXt/jS5HMLqF4REobCzq/LV3TC+MIp3DgT3zEk8dpJijFhX
  mvMis52P8O4u95NVKVfjvRZcW/fXYWALaFDms7pUJnnteuggVVpzF2ZB84wxB3Op
  8FSUyhD9rPZLqOOuEfaFfzySSAwN8qger1gYgrzzCEDXKmsigam2NdTeHqnBx7dW
  nZ2mWI43dw3K9zwo30njAPPELb4CuK7I80ZV7gb3Uo13qe5oN6zXjwc/zYrFkTDm
  C4m3WtD2buRS/kf5o/+3U/IPmvseekE//IoZ3ZqWh3pJhFvnAiv0mb8cKXA5Rl2U
  OBiJCYv0CChnwYhjWmr+Ot9HdHcHqM4=
  -----END CERTIFICATE-----
  """

  test "import_xml applies local XML metadata through the metadata-specific pipeline" do
    connection = insert_enabled_connection!("01JT72VWKG9CEZ8SAC9X2T4FJ1")

    assert {:ok, revision} =
             Metadata.import_xml(connection.connection_id, metadata_xml(),
               repo: @repo,
               actor: "operator@example.com"
             )

    updated =
      @repo.get_by!(Connection, connection_id: connection.connection_id)
      |> @repo.preload(:certificates)

    assert revision.source_kind == :xml_import
    assert updated.idp_entity_id == "https://idp.example.com/metadata"
    assert updated.idp_sso_url == "https://idp.example.com/sso/redirect"
    assert Enum.count(updated.certificates) == 3

    assert Enum.any?(
             updated.certificates,
             &(&1.fingerprint_sha256 == "fp-existing" and &1.lifecycle_state == :active)
           )

    assert Enum.any?(updated.certificates, &(&1.lifecycle_state == :next))
  end

  test "import_xml records durable failures for malformed XML, wrong root, and missing SSO service" do
    connection = insert_enabled_connection!("01JT72VWKG9CEZ8SAC9X2T4FJ2")

    assert {:error, %Relyra.Error{type: :malformed_xml}} =
             Metadata.import_xml(connection.connection_id, "<EntityDescriptor>", repo: @repo)

    assert {:error, %Relyra.Error{type: :metadata_wrong_root}} =
             Metadata.import_xml(connection.connection_id, "<Response></Response>", repo: @repo)

    assert {:error, %Relyra.Error{type: :metadata_missing_sso_service}} =
             Metadata.import_xml(connection.connection_id, metadata_xml_without_sso(),
               repo: @repo
             )
  end

  test "import_xml prefers HTTP-Redirect over HTTP-POST over remaining SingleSignOnService endpoints" do
    connection = insert_enabled_connection!("01JT72VWKG9CEZ8SAC9X2T4FJ3")

    assert {:ok, _revision} =
             Metadata.import_xml(connection.connection_id, metadata_xml(), repo: @repo)

    updated = @repo.get_by!(Connection, connection_id: connection.connection_id)
    assert updated.idp_sso_url == "https://idp.example.com/sso/redirect"
  end

  test "build_candidate normalizes one authoritative certificate collection and preserves typed invalid PEM facts" do
    candidate =
      Import.build_candidate(%{
        entity_id: "https://idp.example.com/metadata",
        sso_services: [
          %{
            binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
            location: "https://idp.example.com/sso/redirect"
          }
        ],
        certificates: [pem_body(@cert_one_pem), "not-valid-base64"]
      })

    assert length(candidate.certificates) == 2
    assert candidate.certificate_facts == candidate.certificates

    assert Enum.map(candidate.certificates, & &1.pem) == candidate.certificate_pems

    assert Enum.map(candidate.certificates, & &1.fingerprint_sha256) ==
             candidate.certificate_fingerprints

    assert [%{not_before: %DateTime{}, not_after: %DateTime{}}, %{error: error}] =
             candidate.certificates

    assert %Relyra.Error{
             type: :invalid_connection_record,
             details: %{reason: :invalid_certificate_pem}
           } =
             error
  end

  test "import_xml returns a typed invalid_certificate_pem error for malformed metadata certificate input" do
    connection = insert_enabled_connection!("01JT72VWKG9CEZ8SAC9X2T4FJ6")

    assert {:error, %Relyra.Error{type: :invalid_connection_record, details: details}} =
             Metadata.import_xml(
               connection.connection_id,
               metadata_xml(certificates: ["not-valid-base64"]), repo: @repo)

    assert details.reason == :invalid_certificate_pem
  end

  test "register_source stores one remote HTTPS source per connection without touching runtime resolver state" do
    connection = insert_enabled_connection!("01JT72VWKG9CEZ8SAC9X2T4FJ4")
    original = @repo.get_by!(Connection, connection_id: connection.connection_id)

    assert {:ok, source} =
             Metadata.register_source(
               connection.connection_id,
               %{
                 url: "https://idp.example.com/metadata",
                 actor: "operator@example.com",
                 cause: "runtime resolver registration"
               },
               repo: @repo
             )

    assert source.last_outcome == :registered

    assert {:ok, replacement} =
             Metadata.register_source(
               connection.connection_id,
               %{
                 url: "https://idp.example.com/metadata-v2",
                 actor: "operator@example.com",
                 cause: "replace"
               },
               repo: @repo
             )

    assert replacement.id == source.id
    assert replacement.connection_record_id == source.connection_record_id

    assert {:ok, resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved.idp_entity_id == original.idp_entity_id
    assert resolved.idp_sso_url == original.idp_sso_url

    assert original.active_metadata_revision_id ==
             @repo.get!(Connection, original.id).active_metadata_revision_id
  end

  test "register_source rejects non-https urls and missing repo configuration" do
    connection = insert_enabled_connection!("01JT72VWKG9CEZ8SAC9X2T4FJ5")

    assert {:error, %Relyra.Error{type: :invalid_connection_record}} =
             Metadata.register_source(
               connection.connection_id,
               %{
                 url: "http://idp.example.com/metadata",
                 actor: "operator@example.com",
                 cause: "insecure"
               },
               repo: @repo
             )

    assert {:error, %Relyra.Error{type: :adapter_not_configured}} =
             Metadata.register_source(connection.connection_id, %{
               url: "https://idp.example.com/metadata"
             })
  end

  defp insert_enabled_connection!(connection_id) do
    now = DateTime.utc_now()

    connection =
      %Connection{
        id: Ecto.UUID.generate(),
        connection_id: connection_id,
        status: :enabled,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://existing.idp.example.com/entity",
        idp_sso_url: "https://existing.idp.example.com/sso",
        inserted_at: now,
        updated_at: now
      }
      |> @repo.insert!()

    %Certificate{
      id: Ecto.UUID.generate(),
      connection_record_id: connection.id,
      fingerprint_sha256: "fp-existing",
      pem: "-----BEGIN CERTIFICATE-----\nEXISTING\n-----END CERTIFICATE-----",
      source: "manual",
      role: :signing,
      lifecycle_state: :active,
      activated_at: now,
      inserted_at: now,
      updated_at: now,
      metadata: %{}
    }
    |> @repo.insert!()

    connection
  end

  defp metadata_xml(opts \\ []) do
    certificates =
      Keyword.get(opts, :certificates, [pem_body(@cert_one_pem), pem_body(@cert_two_pem)])

    certificate_xml =
      certificates
      |> Enum.map_join("\n", fn certificate ->
        """
        <KeyDescriptor use="signing">
          <KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
            <X509Data>
              <X509Certificate>#{certificate}</X509Certificate>
            </X509Data>
          </KeyInfo>
        </KeyDescriptor>
        """
      end)

    """
    <EntityDescriptor entityID="https://idp.example.com/metadata" xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
      <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        #{certificate_xml}
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://idp.example.com/sso/post"/>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://idp.example.com/sso/redirect"/>
      </IDPSSODescriptor>
    </EntityDescriptor>
    """
  end

  defp metadata_xml_without_sso do
    """
    <EntityDescriptor entityID="https://idp.example.com/metadata" xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
      <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <KeyDescriptor use="signing">
          <KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
            <X509Data>
              <X509Certificate>#{pem_body(@cert_one_pem)}</X509Certificate>
            </X509Data>
          </KeyInfo>
        </KeyDescriptor>
      </IDPSSODescriptor>
    </EntityDescriptor>
    """
  end

  defp pem_body(pem) do
    pem
    |> String.replace("-----BEGIN CERTIFICATE-----\n", "")
    |> String.replace("\n-----END CERTIFICATE-----\n", "")
    |> String.replace("\n", "")
  end
end
