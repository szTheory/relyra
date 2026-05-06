defmodule Relyra.Ecto.CertificateInventoryExpiryTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Ecto.{Certificate, Connection, MetadataApply, MetadataRevision}
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

  test "metadata import stages next certificates with persisted not_before and not_after facts" do
    connection = insert_enabled_connection!("01JT8VQFGS39DWXDC2M7GMQ5A1")

    candidate =
      Import.build_candidate(%{
        entity_id: "https://metadata.idp.example.com/entity",
        sso_services: [
          %{
            binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
            location: "https://metadata.idp.example.com/sso/redirect"
          }
        ],
        certificates: [pem_body(@cert_one_pem), pem_body(@cert_two_pem)]
      })

    assert {:ok, revision} =
             MetadataApply.apply_revision(
               connection.connection_id,
               Map.from_struct(candidate),
               applied_revision_attrs(),
               repo: @repo
             )

    updated =
      @repo.get_by!(Connection, connection_id: connection.connection_id)
      |> @repo.preload(:certificates)

    staged =
      updated.certificates
      |> Enum.filter(&(&1.lifecycle_state == :next))
      |> Enum.sort_by(& &1.fingerprint_sha256)

    assert Enum.map(staged, & &1.fingerprint_sha256) ==
             candidate.certificates
             |> Enum.map(& &1.fingerprint_sha256)
             |> Enum.sort()

    assert candidate.certificate_facts == candidate.certificates
    assert Enum.map(candidate.certificates, & &1.pem) == candidate.certificate_pems

    assert Enum.map(candidate.certificates, & &1.fingerprint_sha256) ==
             candidate.certificate_fingerprints

    assert Enum.map(staged, & &1.lifecycle_state) == [:next, :next]

    assert Enum.map(staged, &{&1.not_before, &1.not_after}) == [
             {
               ~U[2026-05-05 20:18:50.000000Z],
               ~U[2026-06-04 20:18:50.000000Z]
             },
             {
               ~U[2026-05-05 20:18:50.000000Z],
               ~U[2026-08-03 20:18:50.000000Z]
             }
           ]

    assert Enum.all?(staged, fn cert ->
             cert.metadata == %{"metadata_revision_id" => revision.id} and
               String.starts_with?(cert.source, "metadata_revision:")
           end)
  end

  test "persisted validity timestamps reflect PEM facts, not staged_at or revision timestamps" do
    connection = insert_enabled_connection!("01JT8VQFGS39DWXDC2M7GMQ5A2")

    candidate =
      Import.build_candidate(%{
        entity_id: "https://metadata.idp.example.com/entity",
        sso_services: [
          %{
            binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
            location: "https://metadata.idp.example.com/sso/redirect"
          }
        ],
        certificates: [pem_body(@cert_one_pem)]
      })

    assert {:ok, _revision} =
             MetadataApply.apply_revision(
               connection.connection_id,
               Map.from_struct(candidate),
               applied_revision_attrs(),
               repo: @repo
             )

    persisted =
      @repo.get_by!(Connection, connection_id: connection.connection_id)
      |> @repo.preload(:certificates)
      |> Map.fetch!(:certificates)
      |> Enum.find(&(&1.lifecycle_state == :next))

    assert persisted.not_before == ~U[2026-05-05 20:18:50.000000Z]
    assert persisted.not_after == ~U[2026-06-04 20:18:50.000000Z]
    refute persisted.not_before == persisted.staged_at
    refute persisted.not_after == persisted.staged_at
  end

  test "malformed PEM input returns a typed error and leaves no partial staged rows behind" do
    connection = insert_enabled_connection!("01JT8VQFGS39DWXDC2M7GMQ5A3")
    original_count = certificate_count(connection.connection_id)

    candidate =
      Import.build_candidate(%{
        entity_id: "https://metadata.idp.example.com/entity",
        sso_services: [
          %{
            binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
            location: "https://metadata.idp.example.com/sso/redirect"
          }
        ],
        certificates: ["not-valid-base64"]
      })

    assert [%{error: %Relyra.Error{details: %{reason: :invalid_certificate_pem}}}] =
             candidate.certificates

    assert {:error, %Relyra.Error{type: :invalid_connection_record, details: details}} =
             MetadataApply.apply_revision(
               connection.connection_id,
               Map.from_struct(candidate),
               applied_revision_attrs(),
               repo: @repo
             )

    assert details.reason == :invalid_certificate_pem
    assert certificate_count(connection.connection_id) == original_count

    persisted =
      @repo.get_by!(Connection, connection_id: connection.connection_id)
      |> @repo.preload(:certificates)

    assert Enum.map(persisted.certificates, & &1.lifecycle_state) == [:active]
  end

  defp certificate_count(connection_id) do
    @repo.get_by!(Connection, connection_id: connection_id)
    |> @repo.preload(:certificates)
    |> Map.fetch!(:certificates)
    |> length()
  end

  defp pem_body(pem) do
    pem
    |> String.replace("-----BEGIN CERTIFICATE-----\n", "")
    |> String.replace("\n-----END CERTIFICATE-----\n", "")
    |> String.replace("\n", "")
  end

  defp insert_enabled_connection!(connection_id) do
    now = DateTime.utc_now()

    {:ok, connection} =
      %Connection{
        id: Ecto.UUID.generate(),
        connection_id: connection_id,
        status: :draft,
        inserted_at: now,
        updated_at: now
      }
      |> @repo.insert()

    {:ok, prior_revision} =
      %MetadataRevision{}
      |> MetadataRevision.changeset(%{
        connection_record_id: connection.id,
        source_kind: :xml_import,
        trigger: :manual_import,
        outcome: :applied,
        trust_summary: %{status: "seed"}
      })
      |> @repo.insert()

    connection =
      connection
      |> Ecto.Changeset.change(%{
        status: :enabled,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://old.idp.example.com/entity",
        idp_sso_url: "https://old.idp.example.com/sso",
        active_metadata_revision_id: prior_revision.id,
        last_known_good_metadata_revision_id: prior_revision.id,
        updated_at: now
      })
      |> @repo.update!()

    %Certificate{
      id: Ecto.UUID.generate(),
      connection_record_id: connection.id,
      fingerprint_sha256: "fp-old",
      pem: "-----BEGIN CERTIFICATE-----\nOLD\n-----END CERTIFICATE-----",
      source: "manual",
      role: :signing,
      lifecycle_state: :active,
      activated_at: now,
      inserted_at: now,
      updated_at: now,
      metadata: %{}
    }
    |> @repo.insert!()

    @repo.get!(Connection, connection.id)
  end

  defp applied_revision_attrs do
    %{
      source_kind: :xml_import,
      trigger: :manual_import,
      outcome: :applied,
      actor: "operator@example.com",
      cause: "manual import",
      trust_summary: %{status: "applied", certificate_count: 2}
    }
  end
end
