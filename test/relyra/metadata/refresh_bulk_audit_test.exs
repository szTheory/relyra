defmodule Relyra.Metadata.RefreshBulkAuditTest do
  @moduledoc """
  Phase 21.1 CFG-07 closure — bulk-refresh audit correlation_id forwarding
  regression suite. Closes v0.5 milestone audit BLOCKER INT-01.

  Asserts the Phase 20 D-39 batch-cohesion invariant for the
  `:refresh_metadata` bulk action: every per-connection audit row in a bulk
  run shares ONE correlation_id and carries the bulk audit map's actor/cause.
  """

  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Ecto.{AuditEvent, BulkActions, Certificate, Connection, MetadataRevision}
  alias Relyra.Metadata

  @repo Relyra.TestSupport.EctoTestRepo
  @stub __MODULE__.ReqStub

  describe "bulk refresh — D-39 audit correlation cohesion" do
    test "[CFG-07] bulk refresh produces N audit rows sharing one correlation_id with bulk actor/cause" do
      conns =
        for i <- 1..3 do
          insert_enabled_connection!("01JT74Q2YJ9WFM0MMSYF6QK4M#{i}A")
        end

      Enum.each(conns, &register_source!(&1.connection_id))

      Req.Test.stub(@stub, fn conn ->
        Req.Test.text(conn, metadata_xml())
      end)

      ids = Enum.map(conns, & &1.connection_id)

      audit = %{
        actor: "ops@example.com",
        cause: "live_admin_bulk_refresh_metadata"
      }

      {:ok, results} =
        BulkActions.run(@repo, ids, &Metadata.refresh/2,
          audit: audit,
          req: Req.new(plug: {Req.Test, @stub})
        )

      # Assertion 1: every per-connection refresh succeeded
      assert Enum.all?(results, fn {_id, res} -> match?({:ok, _}, res) end),
             "expected all bulk refreshes to succeed, got: " <> inspect(results)

      # Assertion 2: exactly 3 :metadata, :applied audit rows
      applied_events = applied_metadata_events()
      assert length(applied_events) == 3

      # Assertion 3: all 3 share ONE non-nil correlation_id (THE gap-closure check)
      correlation_ids = applied_events |> Enum.map(& &1.correlation_id) |> Enum.uniq()

      assert length(correlation_ids) == 1,
             "expected one shared correlation_id, got: " <> inspect(correlation_ids)

      assert hd(correlation_ids) != nil,
             "expected non-nil correlation_id; pre-fix the gap leaves it nil"

      # Assertion 4: actor/cause come from the bulk audit map (not unknown / manual refresh)
      assert Enum.all?(applied_events, &(&1.actor == "ops@example.com")),
             "expected actor='ops@example.com' on every row, got: " <>
               inspect(Enum.map(applied_events, & &1.actor))

      assert Enum.all?(applied_events, &(&1.cause == "live_admin_bulk_refresh_metadata")),
             "expected cause='live_admin_bulk_refresh_metadata' on every row, got: " <>
               inspect(Enum.map(applied_events, & &1.cause))
    end
  end

  describe "single-connection refresh — D-21.1-03 fallback regression guard" do
    test "[CFG-07] top-level :actor / :cause keyword opts (no :audit map) still produce a valid audit row" do
      connection = insert_enabled_connection!("01JT74Q2YJ9WFM0MMSYF6QK4M9B")
      register_source!(connection.connection_id)

      Req.Test.stub(@stub, fn conn ->
        Req.Test.text(conn, metadata_xml())
      end)

      assert {:ok, _revision} =
               Metadata.refresh(connection.connection_id,
                 repo: @repo,
                 req: Req.new(plug: {Req.Test, @stub}),
                 actor: "ops@example.com",
                 cause: "live_admin_metadata_refresh"
               )

      [event] = applied_metadata_events()
      assert event.actor == "ops@example.com"
      assert event.cause == "live_admin_metadata_refresh"

      assert is_nil(event.correlation_id),
             "single-connection refresh should produce nil correlation_id (no batch); got: " <>
               inspect(event.correlation_id)
    end
  end

  describe "failure path — D-35 single-audit-writer-seam invariant" do
    test "[CFG-07] bulk refresh with one parse-failure produces NO :metadata, :applied row for the failing connection" do
      good = insert_enabled_connection!("01JT74Q2YJ9WFM0MMSYF6QK4M9C")
      bad = insert_enabled_connection!("01JT74Q2YJ9WFM0MMSYF6QK4M9D")

      register_source!(good.connection_id)
      register_source_with_url!(bad.connection_id, "https://malformed.idp.example.com/metadata")

      Req.Test.stub(@stub, fn conn ->
        case conn.host do
          "malformed.idp.example.com" -> Req.Test.text(conn, "<EntityDescriptor>")
          _ -> Req.Test.text(conn, metadata_xml())
        end
      end)

      audit = %{
        actor: "ops@example.com",
        cause: "live_admin_bulk_refresh_metadata"
      }

      {:ok, results} =
        BulkActions.run(
          @repo,
          [good.connection_id, bad.connection_id],
          &Metadata.refresh/2,
          audit: audit,
          req: Req.new(plug: {Req.Test, @stub})
        )

      # Assertion 1+2: success/failure split per-id
      assert match?({:ok, _}, results[good.connection_id])
      assert match?({:error, %Relyra.Error{}}, results[bad.connection_id])

      # Assertion 3: exactly ONE :metadata, :applied row (the good one only)
      applied = applied_metadata_events()

      assert length(applied) == 1,
             "expected exactly 1 applied event (the good connection only), got: " <>
               inspect(applied)

      # Assertion 4: that row has the bulk correlation_id (proves bulk wiring ran)
      assert hd(applied).correlation_id != nil

      # Assertion 5: the failing connection produced a non-applied MetadataRevision row
      bad_record = @repo.get_by!(Connection, connection_id: bad.connection_id)

      failure_revisions =
        MetadataRevision
        |> @repo.all()
        |> Enum.filter(&(&1.connection_record_id == bad_record.id))

      assert Enum.any?(failure_revisions, &(&1.outcome != :applied)),
             "expected at least one non-:applied MetadataRevision for the failing connection"
    end
  end

  # --- Fixture helpers (copied verbatim from test/relyra/metadata_refresh_test.exs) ---

  defp applied_metadata_events do
    AuditEvent
    |> @repo.all()
    |> Enum.filter(&(&1.domain == :metadata and &1.action == :applied))
  end

  defp register_source!(connection_id) do
    {:ok, _source} =
      Metadata.register_source(
        connection_id,
        %{
          url: "https://idp.example.com/metadata",
          actor: "operator@example.com",
          cause: "refresh registration"
        },
        repo: @repo
      )
  end

  defp register_source_with_url!(connection_id, url) do
    {:ok, _source} =
      Metadata.register_source(
        connection_id,
        %{
          url: url,
          actor: "operator@example.com",
          cause: "refresh registration"
        },
        repo: @repo
      )
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

  defp metadata_xml do
    """
    <EntityDescriptor entityID="https://refresh.idp.example.com/metadata" xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
      <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <KeyDescriptor use="signing">
          <KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
            <X509Data>
              <X509Certificate>#{refresh_certificate_body()}</X509Certificate>
            </X509Data>
          </KeyInfo>
        </KeyDescriptor>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://refresh.idp.example.com/sso/redirect"/>
      </IDPSSODescriptor>
    </EntityDescriptor>
    """
  end

  defp refresh_certificate_body do
    refresh_certificate_pem()
    |> String.replace("-----BEGIN CERTIFICATE-----\n", "")
    |> String.replace("\n-----END CERTIFICATE-----\n", "")
    |> String.replace("\n", "")
  end

  defp refresh_certificate_pem do
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
