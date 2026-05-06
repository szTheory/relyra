defmodule Relyra.Ecto.CertificateInventoryConcurrencyTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Relyra.ConnectionResolver.Ecto, as: EctoResolver
  alias Relyra.Ecto.{Certificate, CertificateInventory, Connection}
  alias Relyra.TestSupport.MigrationCase

  @repo Relyra.TestSupport.EctoTestRepo

  setup do
    Sandbox.mode(@repo, :auto)
    MigrationCase.reset_tables!()

    on_exit(fn ->
      MigrationCase.reset_tables!()
      Sandbox.mode(@repo, :manual)
    end)

    :ok
  end

  test "concurrent promotion attempts fail closed and preserve one explicit active trust set" do
    connection = insert_enabled_connection!("01JT91ZC4FQ4YFATK0XQ8GCB11")
    parent = self()

    conflicting_task =
      Task.async(fn ->
        receive do
          :start -> :ok
        end

        CertificateInventory.activate_signing_certificate(
          @repo,
          connection.connection_id,
          "next-b",
          after_fetch: fn ->
            send(parent, :stale_fetch_complete)

            receive do
              :continue_after_fetch -> :ok
            end
          end
        )
      end)

    send(conflicting_task.pid, :start)
    assert_receive :stale_fetch_complete, 1_000

    assert {:ok, promoted} =
             CertificateInventory.activate_signing_certificate(
               @repo,
               connection.connection_id,
               "next-a"
             )

    assert promoted.fingerprint_sha256 == "next-a"

    send(conflicting_task.pid, :continue_after_fetch)

    assert {:error, %Relyra.Error{details: details}} = Task.await(conflicting_task, 1_000)
    assert details.reason == :conflict

    assert {:ok, resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----",
             "-----BEGIN CERTIFICATE-----\nNEXT-A\n-----END CERTIFICATE-----"
           ]
  end

  defp insert_enabled_connection!(connection_id) do
    now = DateTime.utc_now()

    connection =
      %Connection{
        id: Ecto.UUID.generate(),
        connection_id: connection_id,
        display_name: "Concurrency test",
        organization_id: "org_concurrency",
        status: :enabled,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://idp.example.com/metadata",
        idp_sso_url: "https://idp.example.com/sso",
        inserted_at: now,
        updated_at: now
      }
      |> @repo.insert!()

    insert_certificate!(connection.id, %{
      fingerprint_sha256: "active-cert",
      pem: "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----",
      lifecycle_state: :active,
      activated_at: now
    })

    insert_certificate!(connection.id, %{
      fingerprint_sha256: "next-a",
      pem: "-----BEGIN CERTIFICATE-----\nNEXT-A\n-----END CERTIFICATE-----",
      lifecycle_state: :next,
      staged_at: now
    })

    insert_certificate!(connection.id, %{
      fingerprint_sha256: "next-b",
      pem: "-----BEGIN CERTIFICATE-----\nNEXT-B\n-----END CERTIFICATE-----",
      lifecycle_state: :next,
      staged_at: now
    })

    @repo.get!(Connection, connection.id)
  end

  defp insert_certificate!(connection_id, attrs) do
    %Certificate{
      id: Ecto.UUID.generate(),
      connection_record_id: connection_id,
      source: "manual",
      role: :signing,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
    |> Certificate.changeset(attrs)
    |> @repo.insert!()
  end
end
