defmodule Relyra.Ecto.AuditHardeningTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Ecto.{
    AuditEvent,
    AuditWriter,
    Certificate,
    CertificateInventory,
    Connection,
    Connections,
    MappingCommands,
    MetadataApply
  }

  alias Relyra.Metadata.Import

  @repo Relyra.TestSupport.EctoTestRepo

  test "append_event redacts sensitive payloads and stores bounded summaries" do
    connection = insert_connection!("01JT9AUDITHARDENING000001")

    assert {:ok, event} =
             AuditWriter.append_event(@repo, %{
               connection_record_id: connection.id,
               domain: :connection,
               action: :updated,
               actor: "ops@example.com",
               cause: "rotation",
               correlation_id: "corr-123",
               subject_ref: "connection:rotation",
               before_view: %{status: :draft, xml: "<xml>secret</xml>"},
               after_view: %{
                 status: :enabled,
                 certificate_pem:
                   "-----BEGIN CERTIFICATE-----\nSECRET\n-----END CERTIFICATE-----",
                 oversized: String.duplicate("x", 900)
               },
               diff_summary: %{changed_fields: [:status, :pem]},
               metadata: %{pem: "-----BEGIN CERTIFICATE-----\nMETA\n-----END CERTIFICATE-----"}
             })

    assert event.actor == "ops@example.com"
    assert event.cause == "rotation"
    assert event.before_summary.xml == "[REDACTED]"
    assert event.after_summary.certificate_pem == "[REDACTED]"
    assert event.after_summary.oversized == "[REDACTED]"
    assert event.diff_summary.context.subject_ref == "connection:rotation"
    assert event.diff_summary.context.metadata.pem == "[REDACTED]"
  end

  test "append_event requires explicit attribution and ignores ambient process state" do
    connection = insert_connection!("01JT9AUDITHARDENING000002")
    Process.put(:audit_actor, "ambient@example.com")
    Process.put(:audit_cause, "ambient")

    assert {:error, %Relyra.Error{details: details}} =
             AuditWriter.append_event(@repo, %{
               connection_record_id: connection.id,
               domain: :connection,
               action: :created,
               before_view: %{},
               after_view: %{status: :draft},
               diff_summary: %{changed_fields: [:status]}
             })

    assert :actor in details.missing
    assert :cause in details.missing
    assert @repo.aggregate(AuditEvent, :count) == 0
  after
    Process.delete(:audit_actor)
    Process.delete(:audit_cause)
  end

  test "cross-domain audit rows stay attributable, reviewable, and redaction-safe" do
    audit = %{actor: "ops@example.com", cause: "manual_change", correlation_id: "corr-review"}

    assert {:ok, created} =
             Connections.create(
               %{
                 display_name: "Reviewable audit connection",
                 organization_id: "org_review"
               },
               repo: @repo,
               audit: audit
             )

    assert {:ok, updated} =
             Connections.update(
               created.connection_id,
               %{
                 sp_entity_id: "https://sp.example.com/metadata",
                 acs_url: "https://sp.example.com/saml/acs",
                 idp_entity_id: "https://idp.example.com/entity",
                 idp_sso_url: "https://idp.example.com/sso",
                 runtime_policy: %{
                   allow_idp_initiated?: false,
                   require_signed_assertions?: true,
                   require_signed_response?: true
                 }
               },
               repo: @repo,
               audit: audit
             )

    insert_certificate!(updated.id, %{
      fingerprint_sha256: "fp-old",
      activated_at: DateTime.utc_now()
    })

    assert {:ok, enabled} = Connections.enable(updated.connection_id, repo: @repo, audit: audit)

    assert {:ok, revision} =
             MetadataApply.apply_revision(
               enabled.connection_id,
               candidate(),
               %{
                 source_kind: :xml_import,
                 trigger: :manual_import,
                 outcome: :applied,
                 actor: "operator@example.com",
                 cause: "manual import",
                 correlation_id: "meta-123",
                 trust_summary: %{status: "applied", certificate_count: 2},
                 details: %{metadata_xml: "<xml>secret</xml>"}
               },
               repo: @repo
             )

    assert {:ok, _cert} =
             CertificateInventory.activate_signing_certificate(
               @repo,
               enabled.connection_id,
               List.first(candidate().certificate_fingerprints),
               audit: %{
                 actor: "ops@example.com",
                 cause: "promote_next",
                 correlation_id: "cert-123"
               }
             )

    assert {:ok, _result} =
             MappingCommands.replace_attribute_mappings(
               enabled.connection_id,
               [
                 %{
                   source_attribute: "preferred_email",
                   target_field: :email,
                   multivalue_strategy: :first
                 }
               ],
               repo: @repo,
               audit: %{
                 actor: "ops@example.com",
                 cause: "update_mapping",
                 correlation_id: "map-123"
               }
             )

    events =
      AuditEvent
      |> @repo.all()
      |> Enum.sort_by(&DateTime.to_unix(&1.inserted_at, :microsecond))

    assert length(events) == 7

    assert domains_and_actions(events) == [
             {:connection, :created},
             {:connection, :updated},
             {:connection, :enabled},
             {:certificate, :staged},
             {:metadata, :applied},
             {:certificate, :activated},
             {:mapping, :created}
           ]

    assert Enum.all?(events, &reviewable_event?/1)
    assert Enum.all?(events, &(present_text?(&1.actor) and present_text?(&1.cause)))
    assert Enum.any?(events, & &1.diff_summary["mapping_revision_id"])
    assert Enum.any?(events, &(metadata_revision_ref(&1) == revision.id))

    assert_redaction_safe!(events)
  end

  defp insert_connection!(connection_id) do
    now = DateTime.utc_now()

    %Connection{
      id: Ecto.UUID.generate(),
      connection_id: connection_id,
      display_name: "Audit hardening",
      organization_id: "org_audit",
      status: :draft,
      inserted_at: now,
      updated_at: now
    }
    |> @repo.insert!()
  end

  defp insert_certificate!(connection_record_id, overrides) do
    now = DateTime.utc_now()

    %Certificate{
      id: Ecto.UUID.generate(),
      connection_record_id: connection_record_id,
      fingerprint_sha256: Map.get(overrides, :fingerprint_sha256, "fp-default"),
      pem:
        Map.get(
          overrides,
          :pem,
          "-----BEGIN CERTIFICATE-----\nOLD\n-----END CERTIFICATE-----"
        ),
      source: Map.get(overrides, :source, "manual"),
      role: Map.get(overrides, :role, :signing),
      lifecycle_state: Map.get(overrides, :lifecycle_state, :active),
      activated_at: Map.get(overrides, :activated_at),
      staged_at: Map.get(overrides, :staged_at),
      retired_at: Map.get(overrides, :retired_at),
      inserted_at: now,
      updated_at: now,
      metadata: %{}
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

  defp pem_body(pem) do
    pem
    |> String.replace("-----BEGIN CERTIFICATE-----\n", "")
    |> String.replace("\n-----END CERTIFICATE-----\n", "")
    |> String.replace("\n", "")
  end

  defp domains_and_actions(events), do: Enum.map(events, &{&1.domain, &1.action})

  defp reviewable_event?(event) do
    changed_fields = Map.get(event.diff_summary, "changed_fields", [])

    map_size(event.after_summary) > 0 and
      is_list(changed_fields) and changed_fields != [] and
      summarizes_trust_change?(event)
  end

  defp summarizes_trust_change?(%AuditEvent{domain: :connection} = event) do
    present_text?(event.after_summary["status"]) and
      is_list(Map.get(event.diff_summary, "changed_fields", []))
  end

  defp summarizes_trust_change?(%AuditEvent{domain: :metadata} = event) do
    is_list(Map.get(event.diff_summary, "certificate_fingerprints", [])) and
      present_text?(metadata_revision_ref(event)) and
      is_list(Map.get(event.after_summary, "certificate_inventory", []))
  end

  defp summarizes_trust_change?(%AuditEvent{domain: :certificate} = event) do
    is_list(Map.get(event.after_summary, "active_signing_fingerprints", [])) and
      is_list(Map.get(event.after_summary, "certificates", []))
  end

  defp summarizes_trust_change?(%AuditEvent{domain: :mapping} = event) do
    present_text?(event.diff_summary["mapping_revision_id"]) and
      is_list(Map.get(event.after_summary, "attribute_rules", []))
  end

  defp summarizes_trust_change?(_event), do: false

  defp assert_redaction_safe!(events) do
    serialized =
      events
      |> Enum.map(fn event ->
        %{
          before_summary: event.before_summary,
          after_summary: event.after_summary,
          diff_summary: event.diff_summary
        }
      end)
      |> inspect(limit: :infinity, printable_limit: :infinity)

    refute serialized =~ "<xml>secret</xml>"
    refute serialized =~ "-----BEGIN CERTIFICATE-----"
    refute serialized =~ "private_key"
  end

  defp metadata_revision_ref(event) do
    event.diff_summary
    |> Map.get("context", %{})
    |> Map.get("metadata", %{})
    |> Map.get("metadata_revision_id")
  end

  defp present_text?(value) when is_binary(value), do: String.trim(value) != ""
  defp present_text?(_value), do: false
end
