defmodule Relyra.Ecto.ConnectionCertificateBoundaryTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Ecto.{Certificate, Connection, Connections}

  @repo Relyra.TestSupport.EctoTestRepo

  test "generic connection updates do not delete certificate inventory by omission" do
    connection = insert_enabled_connection!("01JT90FXH3S9WFJJ0CHD9P0K11")
    original_fingerprints = persisted_fingerprints(connection.connection_id)

    assert {:error, %Relyra.Error{type: :invalid_connection_record, details: details}} =
             Connections.update(
               connection.connection_id,
               %{
                 display_name: "Renamed connection",
                 certificates: []
               },
               repo: @repo
             )

    assert details.errors.certificates == [
             "are managed through metadata apply or Relyra.Ecto.CertificateInventory"
           ]

    assert persisted_fingerprints(connection.connection_id) == original_fingerprints
  end

  defp persisted_fingerprints(connection_id) do
    @repo.get_by!(Connection, connection_id: connection_id)
    |> @repo.preload(:certificates)
    |> Map.fetch!(:certificates)
    |> Enum.map(& &1.fingerprint_sha256)
    |> Enum.sort()
  end

  defp insert_enabled_connection!(connection_id) do
    now = DateTime.utc_now()

    connection =
      %Connection{
        id: Ecto.UUID.generate(),
        connection_id: connection_id,
        display_name: "Boundary test",
        organization_id: "org_boundary",
        status: :enabled,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://idp.example.com/metadata",
        idp_sso_url: "https://idp.example.com/sso",
        inserted_at: now,
        updated_at: now
      }
      |> @repo.insert!()

    Enum.each(
      [
        %{
          fingerprint_sha256: "active-boundary",
          pem: "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----",
          lifecycle_state: :active,
          activated_at: now
        },
        %{
          fingerprint_sha256: "next-boundary",
          pem: "-----BEGIN CERTIFICATE-----\nNEXT\n-----END CERTIFICATE-----",
          lifecycle_state: :next,
          staged_at: now
        }
      ],
      fn attrs ->
        %Certificate{
          id: Ecto.UUID.generate(),
          connection_record_id: connection.id,
          source: "manual",
          role: :signing,
          inserted_at: now,
          updated_at: now
        }
        |> Certificate.changeset(attrs)
        |> @repo.insert!()
      end
    )

    @repo.get!(Connection, connection.id)
  end
end
