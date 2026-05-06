defmodule Relyra.ConnectionSnapshotTest do
  use ExUnit.Case, async: true

  alias Relyra.Ecto.{Certificate, Connection, ConnectionSnapshot}
  alias Relyra.Ecto.Connection.RuntimePolicy

  test "hydrate applies provider defaults and canonical certificate mapping" do
    aggregate = %Connection{
      id: Ecto.UUID.generate(),
      connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y5",
      provider_preset: :okta,
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso",
      runtime_policy: %RuntimePolicy{},
      certificates: [
        %Certificate{
          fingerprint_sha256: "abc123",
          pem: "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----",
          source: "manual",
          lifecycle_state: :active,
          role: :signing
        }
      ]
    }

    assert {:ok, snapshot} = ConnectionSnapshot.hydrate(aggregate)
    assert snapshot.idp_certificates == snapshot.cert_chain

    assert snapshot.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----"
           ]

    assert snapshot.provider_preset == :okta
    assert snapshot.allow_idp_initiated? == false
    assert snapshot.require_signed_assertions? == true
    assert snapshot.require_signed_response? == true

    assert snapshot.name_id_format ==
             "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"

    assert snapshot.algorithm_policy == %{signing: :rsa_sha256, digest: :sha256}
  end

  test "hydrate excludes next and retired certificates from the runtime trust set" do
    aggregate = %Connection{
      id: Ecto.UUID.generate(),
      connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y6",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso",
      runtime_policy: %RuntimePolicy{},
      certificates: [
        %Certificate{
          fingerprint_sha256: "active",
          pem: "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----",
          source: "manual",
          lifecycle_state: :active,
          role: :signing
        },
        %Certificate{
          fingerprint_sha256: "next",
          pem: "-----BEGIN CERTIFICATE-----\nNEXT\n-----END CERTIFICATE-----",
          source: "metadata",
          lifecycle_state: :next,
          role: :signing
        },
        %Certificate{
          fingerprint_sha256: "retired",
          pem: "-----BEGIN CERTIFICATE-----\nOLD\n-----END CERTIFICATE-----",
          source: "metadata",
          lifecycle_state: :retired,
          role: :signing
        }
      ]
    }

    assert {:ok, snapshot} = ConnectionSnapshot.hydrate(aggregate)

    assert snapshot.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----"
           ]
  end

  test "hydrate normalizes persisted mapping rows into ordered plain mapping_config" do
    aggregate = %Connection{
      id: Ecto.UUID.generate(),
      connection_id: "01JV2B4ENQDJ6D44AH0R0R5XB1",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso",
      runtime_policy: %RuntimePolicy{},
      certificates: [
        %Certificate{
          fingerprint_sha256: "active",
          pem: "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----",
          source: "manual",
          lifecycle_state: :active,
          role: :signing
        }
      ],
      attribute_mappings: [
        %{
          position: 1,
          source_attribute: "display_names",
          target_field: "display_name",
          multivalue_strategy: "all"
        },
        %{
          position: 0,
          source_attribute: "mail",
          target_field: "email",
          multivalue_strategy: "first"
        }
      ],
      group_mappings: [
        %{
          position: 0,
          source_attribute: "groups",
          source_value: "admins",
          role_target: "role",
          role_value: "admin"
        }
      ]
    }

    assert {:ok, snapshot} = ConnectionSnapshot.hydrate(aggregate)

    assert snapshot.mapping_config == %{
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

    refute Map.has_key?(snapshot, :attribute_mappings)
    refute Map.has_key?(snapshot, :group_mappings)
  end

  test "hydrate leaves mapping_config absent when no persisted mappings exist" do
    aggregate = %Connection{
      id: Ecto.UUID.generate(),
      connection_id: "01JV2B4ENQDJ6D44AH0R0R5XB2",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso",
      runtime_policy: %RuntimePolicy{},
      certificates: [
        %Certificate{
          fingerprint_sha256: "active",
          pem: "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----",
          source: "manual",
          lifecycle_state: :active,
          role: :signing
        }
      ],
      attribute_mappings: [],
      group_mappings: []
    }

    assert {:ok, snapshot} = ConnectionSnapshot.hydrate(aggregate)
    assert snapshot.mapping_config == nil
  end

  test "hydrate keeps mapping_config as the only runtime mapping surface" do
    aggregate = %Connection{
      id: Ecto.UUID.generate(),
      connection_id: "01JV2B4ENQDJ6D44AH0R0R5XB4",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso",
      runtime_policy: %RuntimePolicy{},
      certificates: [
        %Certificate{
          fingerprint_sha256: "active",
          pem: "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----",
          source: "manual",
          lifecycle_state: :active,
          role: :signing
        }
      ],
      attribute_mappings: [
        %{
          position: 0,
          source_attribute: "mail",
          target_field: "email",
          multivalue_strategy: "first"
        }
      ],
      group_mappings: [
        %{
          position: 0,
          source_attribute: "groups",
          source_value: "admins",
          role_target: "role",
          role_value: "admin"
        }
      ]
    }

    assert {:ok, snapshot} = ConnectionSnapshot.hydrate(aggregate)

    runtime_map = Map.from_struct(snapshot)

    assert runtime_map.mapping_config == %{
             attribute_rules: [
               %{
                 source_attribute: "mail",
                 target_field: :email,
                 multivalue_strategy: :first
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

    refute Map.has_key?(runtime_map, :attribute_mappings)
    refute Map.has_key?(runtime_map, :group_mappings)
  end

  test "hydrate fails closed when persisted mapping rows cannot normalize" do
    aggregate = %Connection{
      id: Ecto.UUID.generate(),
      connection_id: "01JV2B4ENQDJ6D44AH0R0R5XB3",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso",
      runtime_policy: %RuntimePolicy{},
      certificates: [
        %Certificate{
          fingerprint_sha256: "active",
          pem: "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----",
          source: "manual",
          lifecycle_state: :active,
          role: :signing
        }
      ],
      attribute_mappings: [
        %{
          position: 0,
          source_attribute: "mail",
          target_field: "regex",
          multivalue_strategy: "first"
        }
      ]
    }

    assert {:error, %Relyra.Error{type: :connection_invalid, details: details}} =
             ConnectionSnapshot.hydrate(aggregate)

    assert details.reason == :invalid_mapping_config
    assert details.mapping_type == :attribute_mappings
  end

  test "hydrate fails closed when trusted certificates are missing" do
    aggregate = %Connection{
      id: Ecto.UUID.generate(),
      connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y5",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso",
      runtime_policy: %RuntimePolicy{},
      certificates: []
    }

    assert {:error, %Relyra.Error{type: :connection_invalid, details: details}} =
             ConnectionSnapshot.hydrate(aggregate)

    assert details.reason == :missing_certificates
  end

  test "hydrate turns unexpected aggregate issues into typed resolver failures" do
    aggregate = %Connection{
      id: Ecto.UUID.generate(),
      connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y5",
      provider_preset: :unknown_provider,
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso",
      runtime_policy: %RuntimePolicy{},
      certificates: [
        %Certificate{
          fingerprint_sha256: "abc123",
          pem: "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----",
          source: "manual"
        }
      ]
    }

    assert {:error, %Relyra.Error{type: :resolver_failed, details: details}} =
             ConnectionSnapshot.hydrate(aggregate)

    assert details.reason == :hydration_failed
  end
end
