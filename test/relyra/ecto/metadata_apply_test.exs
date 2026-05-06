defmodule Relyra.Ecto.MetadataApplyTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.ConnectionResolver.Ecto, as: EctoResolver
  alias Relyra.Metadata.Import

  alias Relyra.Ecto.{
    AuditEvent,
    Certificate,
    CertificateInventory,
    Connection,
    MetadataApply,
    MetadataRevision
  }

  @repo Relyra.TestSupport.EctoTestRepo

  test "apply_revision stages new certificates while preserving the active runtime trust set" do
    connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4H11")

    assert {:ok, revision} =
             MetadataApply.apply_revision(
               connection.connection_id,
               candidate(),
               applied_revision_attrs(),
               repo: @repo
             )

    updated =
      @repo.get_by!(Connection, connection_id: connection.connection_id)
      |> @repo.preload(:certificates)

    assert updated.idp_entity_id == "https://metadata.idp.example.com/entity"
    assert updated.idp_sso_url == "https://metadata.idp.example.com/sso/redirect"
    assert updated.active_metadata_revision_id == revision.id
    assert updated.last_known_good_metadata_revision_id == revision.id

    assert Enum.map(updated.certificates, & &1.fingerprint_sha256) |> Enum.sort() ==
             ["fp-old" | candidate().certificate_fingerprints] |> Enum.sort()

    assert Enum.any?(
             updated.certificates,
             &(&1.fingerprint_sha256 == "fp-old" and &1.lifecycle_state == :active)
           )

    assert Enum.all?(
             Enum.filter(
               updated.certificates,
               &(&1.fingerprint_sha256 in candidate().certificate_fingerprints)
             ),
             fn cert ->
               cert.lifecycle_state == :next and
                 String.starts_with?(cert.source, "metadata_revision:")
             end
           )

    assert {:ok, resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nOLD\n-----END CERTIFICATE-----"
           ]

    events =
      AuditEvent
      |> @repo.all()
      |> Enum.sort_by(&DateTime.to_unix(&1.inserted_at, :microsecond))

    assert Enum.map(events, &{&1.domain, &1.action}) == [
             {:certificate, :staged},
             {:metadata, :applied}
           ]

    assert Enum.at(events, 0).diff_summary["metadata_revision_id"] == revision.id
    assert Enum.at(events, 1).diff_summary["outcome"] == "applied"
  end

  test "apply_revision rolls back revision and certificate changes when certificate data is invalid" do
    connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4H12")

    original =
      @repo.get_by!(Connection, connection_id: connection.connection_id)
      |> @repo.preload(:certificates)

    assert {:error, %Relyra.Error{type: :invalid_connection_record}} =
             MetadataApply.apply_revision(
               connection.connection_id,
               invalid_candidate(),
               applied_revision_attrs(),
               repo: @repo
             )

    refute @repo.get_by(MetadataRevision, effective_idp_entity_id: candidate().idp_entity_id)

    persisted =
      @repo.get_by!(Connection, connection_id: connection.connection_id)
      |> @repo.preload(:certificates)

    assert persisted.idp_entity_id == original.idp_entity_id
    assert persisted.idp_sso_url == original.idp_sso_url
    assert persisted.active_metadata_revision_id == original.active_metadata_revision_id
    assert Enum.map(persisted.certificates, & &1.fingerprint_sha256) == ["fp-old"]

    assert {:ok, resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved.idp_entity_id == original.idp_entity_id
    assert resolved.idp_sso_url == original.idp_sso_url

    assert resolved.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nOLD\n-----END CERTIFICATE-----"
           ]

    assert @repo.aggregate(AuditEvent, :count) == 0
  end

  test "record_attempt persists failed metadata attempts without mutating the runtime aggregate" do
    connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4H13")
    original = @repo.get_by!(Connection, connection_id: connection.connection_id)

    assert {:ok, revision} =
             MetadataApply.record_attempt(
               connection.connection_id,
               %{
                 source_kind: :xml_import,
                 trigger: :manual_import,
                 actor: "operator@example.com",
                 cause: "parse failure",
                 outcome: :parse_failed,
                 details: %{xml: String.duplicate("x", 400)}
               },
               repo: @repo
             )

    assert revision.source_kind == :xml_import
    assert revision.trigger == :manual_import
    assert revision.cause == "parse failure"
    assert revision.details.xml == "[REDACTED]"

    persisted = @repo.get_by!(Connection, connection_id: connection.connection_id)
    assert persisted.active_metadata_revision_id == original.active_metadata_revision_id

    assert persisted.last_known_good_metadata_revision_id ==
             original.last_known_good_metadata_revision_id

    assert {:ok, resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved.idp_entity_id == original.idp_entity_id
    assert resolved.idp_sso_url == original.idp_sso_url
    assert @repo.aggregate(AuditEvent, :count) == 0
  end

  test "activate_signing_certificate and retire_signing_certificate update runtime trust explicitly" do
    connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4H14")

    assert {:ok, revision} =
             MetadataApply.apply_revision(
               connection.connection_id,
               candidate(),
               applied_revision_attrs(),
               repo: @repo
             )

    assert {:ok, _cert} =
             CertificateInventory.activate_signing_certificate(
               @repo,
               connection.connection_id,
               List.first(candidate().certificate_fingerprints),
               audit: %{actor: "ops@example.com", cause: "promote_cert"}
             )

    assert {:ok, resolved_with_overlap} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved_with_overlap.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nOLD\n-----END CERTIFICATE-----",
             List.first(candidate().certificate_pems)
           ]

    assert {:ok, _cert} =
             CertificateInventory.retire_signing_certificate(
               @repo,
               connection.connection_id,
               "fp-old",
               audit: %{actor: "ops@example.com", cause: "retire_old"}
             )

    assert {:ok, resolved_after_retire} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved_after_retire.idp_certificates == [
             List.first(candidate().certificate_pems)
           ]

    assert revision.id == @repo.get!(Connection, connection.id).active_metadata_revision_id

    events =
      AuditEvent
      |> @repo.all()
      |> Enum.sort_by(&DateTime.to_unix(&1.inserted_at, :microsecond))

    assert Enum.map(events, &{&1.domain, &1.action}) == [
             {:certificate, :staged},
             {:metadata, :applied},
             {:certificate, :activated},
             {:certificate, :retired}
           ]
  end

  test "retiring the last active signing certificate is rejected" do
    connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4H15")

    assert {:error, %Relyra.Error{type: :invalid_connection_record, details: details}} =
             CertificateInventory.retire_signing_certificate(
               @repo,
               connection.connection_id,
               "fp-old"
             )

    assert details.reason == :last_active_certificate
  end

  defp insert_enabled_connection!(connection_id) do
    now = DateTime.utc_now()

    {:ok, prior_revision} =
      %MetadataRevision{}
      |> MetadataRevision.changeset(%{
        connection_record_id: insert_draft_connection!(connection_id).id,
        source_kind: :xml_import,
        trigger: :manual_import,
        outcome: :applied,
        trust_summary: %{status: "seed"}
      })
      |> @repo.insert()

    connection =
      @repo.get_by!(Connection, connection_id: connection_id)
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

  defp insert_draft_connection!(connection_id) do
    now = DateTime.utc_now()

    %Connection{
      id: Ecto.UUID.generate(),
      connection_id: connection_id,
      status: :draft,
      inserted_at: now,
      updated_at: now
    }
    |> @repo.insert!()
  end

  defp candidate do
    Import.build_candidate(%{
      entity_id: "https://metadata.idp.example.com/entity",
      sso_services: [
        %{
          binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
          location: "https://metadata.idp.example.com/sso/redirect"
        }
      ],
      certificates: [pem_body(cert_one_pem()), pem_body(cert_two_pem())]
    })
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

  defp invalid_candidate do
    Import.build_candidate(%{
      entity_id: "https://metadata.idp.example.com/entity",
      sso_services: [
        %{
          binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
          location: "https://metadata.idp.example.com/sso/redirect"
        }
      ],
      certificates: ["INVALIDCERTIFICATEBODY"]
    })
    |> Map.from_struct()
  end

  defp pem_body(pem) do
    pem
    |> String.replace("-----BEGIN CERTIFICATE-----\n", "")
    |> String.replace("\n-----END CERTIFICATE-----\n", "")
    |> String.replace("\n", "")
  end

  defp cert_one_pem do
    """
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
  end

  defp cert_two_pem do
    """
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
  end
end
