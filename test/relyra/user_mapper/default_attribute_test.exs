defmodule Relyra.UserMapper.DefaultAttributeTest do
  use ExUnit.Case, async: true

  alias Relyra.UserMapper.DefaultAttribute

  test "prefers persisted mapping_config when present" do
    assertion = %{
      name_id: "name-id-123",
      attributes: %{
        "mail" => "fallback@example.com",
        "preferred_email" => "persisted@example.com",
        "display_names" => ["Primary", "Secondary"],
        "groups" => ["admins", "developers"],
        "given_name" => "Legacy",
        "family_name" => "Fallback"
      }
    }

    connection = %{
      mapping_config: %{
        attribute_rules: [
          %{
            source_attribute: "preferred_email",
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
    }

    assert {:ok, user_map} = DefaultAttribute.map_attributes(assertion, connection)

    assert user_map == %{
             name_id: "name-id-123",
             email: "persisted@example.com",
             first_name: nil,
             last_name: nil,
             display_name: ["Primary", "Secondary"],
             roles: ["admin"]
           }
  end

  test "falls back to legacy hardcoded mapping when persisted mapping_config is absent" do
    assertion = %{
      name_id: "fallback-id",
      attributes: %{
        "mail" => "fallback@example.com",
        "given_name" => "Casey",
        "sn" => "Jones",
        "memberOf" => ["staff", "qa"]
      }
    }

    assert {:ok, user_map} = DefaultAttribute.map_attributes(assertion, %{})

    assert user_map == %{
             name_id: "fallback-id",
             email: "fallback@example.com",
             first_name: "Casey",
             last_name: "Jones",
             roles: ["staff", "qa"]
           }
  end

  test "group mapping uses exact source values only" do
    assertion = %{
      name_id: "group-test",
      attributes: %{
        "groups" => ["admins-team", "developers"]
      }
    }

    connection = %{
      mapping_config: %{
        attribute_rules: [],
        group_rules: [
          %{
            source_attribute: "groups",
            source_value: "admins",
            role_target: :role,
            role_value: "admin"
          },
          %{
            source_attribute: "groups",
            source_value: "developers",
            role_target: :role,
            role_value: "developer"
          }
        ]
      }
    }

    assert {:ok, user_map} = DefaultAttribute.map_attributes(assertion, connection)
    assert user_map.roles == ["developer"]
  end

  test "persisted mapping rules apply in deterministic order for host apps" do
    assertion = %{
      name_id: "ordered-rules",
      attributes: %{
        "display_name" => ["Ada Lovelace", "A. Lovelace"],
        "mail" => "ada@example.com",
        "groups" => ["staff", "admins"]
      }
    }

    connection = %{
      mapping_config: %{
        attribute_rules: [
          %{
            source_attribute: "display_name",
            target_field: :display_name,
            multivalue_strategy: :all
          },
          %{
            source_attribute: "mail",
            target_field: :email,
            multivalue_strategy: :first
          }
        ],
        group_rules: [
          %{
            source_attribute: "groups",
            source_value: "staff",
            role_target: :role,
            role_value: "staff"
          },
          %{
            source_attribute: "groups",
            source_value: "admins",
            role_target: :role,
            role_value: "admin"
          }
        ]
      }
    }

    assert {:ok, user_map} = DefaultAttribute.map_attributes(assertion, connection)

    assert user_map == %{
             name_id: "ordered-rules",
             email: "ada@example.com",
             first_name: nil,
             last_name: nil,
             display_name: ["Ada Lovelace", "A. Lovelace"],
             roles: ["staff", "admin"]
           }
  end
end
