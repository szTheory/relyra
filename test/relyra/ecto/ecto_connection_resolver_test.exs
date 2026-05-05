defmodule Relyra.EctoConnectionResolverTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Connection
  alias Relyra.ConnectionResolver.Ecto, as: EctoResolver
  alias Relyra.Ecto.{Certificate, CertificateInventory}
  alias Relyra.Ecto.Connection, as: ConnectionRecord

  @repo Relyra.TestSupport.EctoTestRepo
  @attribute_table "relyra_attribute_mappings"
  @group_table "relyra_group_mappings"

  test "resolver returns a pure runtime snapshot for enabled persisted connections" do
    connection =
      insert_connection!(%{
        connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y5",
        status: :enabled,
        provider_preset: :okta,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://idp.example.com/metadata",
        idp_sso_url: "https://idp.example.com/sso"
      })

    insert_certificate!(connection.id)

    assert {:ok, %Connection{} = resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved.connection_id == connection.connection_id
    assert resolved.provider_preset == :okta

    assert resolved.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----"
           ]

    assert resolved.__struct__ == Connection
    assert resolved.mapping_config == nil
  end

  test "resolver prefers persisted mapping config and exposes only normalized plain values" do
    connection =
      insert_connection!(%{
        connection_id: "01JV2B4ENQDJ6D44AH0R0R5XC1",
        status: :enabled,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://idp.example.com/metadata",
        idp_sso_url: "https://idp.example.com/sso"
      })

    insert_certificate!(connection.id)
    insert_attribute_mapping!(connection.id, 1, "display_names", "display_name", "all")
    insert_attribute_mapping!(connection.id, 0, "mail", "email", "first")
    insert_group_mapping!(connection.id, 0, "groups", "admins", "role", "admin")

    assert {:ok, %Connection{} = resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved.mapping_config == %{
             attribute_rules: [
               %{
                 source_attribute: "mail",
                 target_field: :email,
                 multivalue_strategy: :first
               },
               %{
                 source_attribute: "display_names",
                 target_field: :display_name,
                 multivalue_strategy: :all
               }
             ],
             group_rules: [
               %{
                 source_attribute: "groups",
                 source_value: "admins",
                 role_target: :role,
                 role_value: "admin"
               }
             ]
           }

    refute Enum.any?(resolved.mapping_config.attribute_rules, &match?(%{__struct__: _}, &1))
    refute Enum.any?(resolved.mapping_config.group_rules, &match?(%{__struct__: _}, &1))
  end

  test "resolver excludes staged certificates from the runtime trust set" do
    connection =
      insert_connection!(%{
        connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7ZB",
        status: :enabled,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://idp.example.com/metadata",
        idp_sso_url: "https://idp.example.com/sso"
      })

    insert_certificate!(connection.id, %{fingerprint_sha256: "active"})
    insert_certificate!(connection.id, %{fingerprint_sha256: "next", lifecycle_state: :next})

    assert {:ok, resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----"
           ]
  end

  test "resolver returns connection_unavailable when the connection does not exist" do
    assert {:error, %Relyra.Error{type: :connection_unavailable, details: details}} =
             EctoResolver.resolve_connection(%{connection_id: "missing"}, repo: @repo)

    assert details.reason == :not_found
  end

  test "resolver distinguishes draft and disabled aggregates" do
    draft =
      insert_connection!(%{
        connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y6",
        status: :draft
      })

    disabled =
      insert_connection!(%{
        connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y7",
        status: :disabled
      })

    assert {:error, %Relyra.Error{type: :connection_unavailable, details: draft_details}} =
             EctoResolver.resolve_connection(%{connection_id: draft.connection_id}, repo: @repo)

    assert draft_details.reason == :draft

    assert {:error, %Relyra.Error{type: :connection_unavailable, details: disabled_details}} =
             EctoResolver.resolve_connection(%{connection_id: disabled.connection_id},
               repo: @repo
             )

    assert disabled_details.reason == :disabled
  end

  test "resolver fails closed for incomplete persisted aggregates" do
    missing_fields =
      insert_connection!(%{
        connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y8",
        status: :enabled,
        sp_entity_id: nil,
        acs_url: nil,
        idp_entity_id: nil,
        idp_sso_url: nil
      })

    missing_certs =
      insert_connection!(%{
        connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y9",
        status: :enabled,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://idp.example.com/metadata",
        idp_sso_url: "https://idp.example.com/sso"
      })

    invalid_certs =
      insert_connection!(%{
        connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7ZA",
        status: :enabled,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://idp.example.com/metadata",
        idp_sso_url: "https://idp.example.com/sso"
      })

    insert_certificate!(invalid_certs.id, %{fingerprint_sha256: "", pem: ""})

    assert {:error, %Relyra.Error{type: :connection_invalid, details: missing_field_details}} =
             EctoResolver.resolve_connection(%{connection_id: missing_fields.connection_id},
               repo: @repo
             )

    assert missing_field_details.reason == :missing_runtime_fields

    assert missing_field_details.missing == [
             :sp_entity_id,
             :acs_url,
             :idp_entity_id,
             :idp_sso_url
           ]

    assert {:error, %Relyra.Error{type: :connection_invalid, details: missing_cert_details}} =
             EctoResolver.resolve_connection(%{connection_id: missing_certs.connection_id},
               repo: @repo
             )

    assert missing_cert_details.reason == :missing_certificates

    assert {:error, %Relyra.Error{type: :connection_invalid, details: invalid_cert_details}} =
             EctoResolver.resolve_connection(%{connection_id: invalid_certs.connection_id},
               repo: @repo
             )

    assert invalid_cert_details.reason == :invalid_certificates
  end

  test "certificate lifecycle transitions support overlap and rollback" do
    connection =
      insert_connection!(%{
        connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7ZC",
        status: :enabled,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://idp.example.com/metadata",
        idp_sso_url: "https://idp.example.com/sso"
      })

    insert_certificate!(connection.id, %{fingerprint_sha256: "active-a"})
    insert_certificate!(connection.id, %{fingerprint_sha256: "next-b", lifecycle_state: :next})

    assert {:ok, _} =
             CertificateInventory.activate_signing_certificate(
               @repo,
               connection.connection_id,
               "next-b"
             )

    assert {:ok, resolved_with_overlap} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert length(resolved_with_overlap.idp_certificates) == 2

    assert {:ok, _} =
             CertificateInventory.retire_signing_certificate(
               @repo,
               connection.connection_id,
               "active-a"
             )

    assert {:ok, resolved_after_retire} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert length(resolved_after_retire.idp_certificates) == 1

    assert {:ok, _} =
             CertificateInventory.rollback_signing_certificate(
               @repo,
               connection.connection_id,
               "active-a",
               "next-b"
             )

    assert {:ok, resolved_after_rollback} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved_after_rollback.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----"
           ]
  end

  test "resolver reports repo misconfiguration with structured details" do
    assert {:error, %Relyra.Error{type: :resolver_misconfigured, details: details}} =
             EctoResolver.resolve_connection(%{connection_id: "valid"}, [])

    assert details.reason == :repo_missing
  end

  defp insert_connection!(attrs) do
    now = DateTime.utc_now()

    %ConnectionRecord{
      id: Ecto.UUID.generate(),
      connection_id: attrs.connection_id,
      display_name: Map.get(attrs, :display_name, "Persisted connection"),
      organization_id: Map.get(attrs, :organization_id, "org_123"),
      status: Map.get(attrs, :status, :draft),
      provider_preset: Map.get(attrs, :provider_preset),
      sp_entity_id: Map.get(attrs, :sp_entity_id),
      acs_url: Map.get(attrs, :acs_url),
      idp_entity_id: Map.get(attrs, :idp_entity_id),
      idp_sso_url: Map.get(attrs, :idp_sso_url),
      runtime_policy: Map.get(attrs, :runtime_policy, %{}),
      inserted_at: now,
      updated_at: now
    }
    |> @repo.insert!()
  end

  defp insert_certificate!(connection_id, overrides \\ %{}) do
    now = DateTime.utc_now()
    lifecycle_state = Map.get(overrides, :lifecycle_state, :active)

    activated_at =
      if lifecycle_state == :active, do: Map.get(overrides, :activated_at, now), else: nil

    staged_at = if lifecycle_state == :next, do: Map.get(overrides, :staged_at, now), else: nil

    retired_at =
      if lifecycle_state == :retired, do: Map.get(overrides, :retired_at, now), else: nil

    %Certificate{
      id: Ecto.UUID.generate(),
      connection_record_id: connection_id,
      fingerprint_sha256: Map.get(overrides, :fingerprint_sha256, "abc123"),
      pem:
        Map.get(overrides, :pem, "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----"),
      source: Map.get(overrides, :source, "manual"),
      role: Map.get(overrides, :role, :signing),
      lifecycle_state: lifecycle_state,
      staged_at: staged_at,
      activated_at: activated_at,
      retired_at: retired_at,
      inserted_at: now,
      updated_at: now,
      metadata: %{}
    }
    |> @repo.insert!()
  end

  defp insert_attribute_mapping!(
         connection_record_id,
         position,
         source_attribute,
         target_field,
         multivalue_strategy
       ) do
    now = DateTime.utc_now()

    @repo.insert_all(@attribute_table, [
      %{
        id: Ecto.UUID.dump!(Ecto.UUID.generate()),
        connection_record_id: Ecto.UUID.dump!(connection_record_id),
        position: position,
        source_attribute: source_attribute,
        target_field: target_field,
        multivalue_strategy: multivalue_strategy,
        inserted_at: now,
        updated_at: now
      }
    ])
  end

  defp insert_group_mapping!(
         connection_record_id,
         position,
         source_attribute,
         source_value,
         role_target,
         role_value
       ) do
    now = DateTime.utc_now()

    @repo.insert_all(@group_table, [
      %{
        id: Ecto.UUID.dump!(Ecto.UUID.generate()),
        connection_record_id: Ecto.UUID.dump!(connection_record_id),
        position: position,
        source_attribute: source_attribute,
        source_value: source_value,
        role_target: role_target,
        role_value: role_value,
        inserted_at: now,
        updated_at: now
      }
    ])
  end
end
