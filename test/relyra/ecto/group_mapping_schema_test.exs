defmodule Relyra.Ecto.GroupMappingSchemaTest do
  use ExUnit.Case, async: true

  alias Relyra.Ecto.GroupMapping

  @valid_attrs %{
    connection_record_id: Ecto.UUID.generate(),
    source_attribute: "groups",
    source_value: "admins",
    role_target: :role,
    role_value: "admin"
  }

  test "group mapping changeset rejects missing required mapping fields" do
    changeset = GroupMapping.changeset(%GroupMapping{}, %{})

    refute changeset.valid?

    errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)

    assert "can't be blank" in errors.connection_record_id
    assert "can't be blank" in errors.source_attribute
    assert "can't be blank" in errors.source_value
    assert "can't be blank" in errors.role_target
    assert "can't be blank" in errors.role_value
  end

  test "group mapping stays exact-match only without regex or expression fields" do
    changeset = GroupMapping.changeset(%GroupMapping{}, @valid_attrs)

    assert changeset.valid?

    fields = GroupMapping.__schema__(:fields)

    refute :regex in fields
    refute :script in fields
    refute :expression in fields
  end

  test "group mapping only accepts the bounded role target enum" do
    valid_changeset = GroupMapping.changeset(%GroupMapping{}, @valid_attrs)

    assert valid_changeset.valid?

    invalid_changeset =
      GroupMapping.changeset(%GroupMapping{}, Map.put(@valid_attrs, :role_target, :group))

    refute invalid_changeset.valid?

    errors = Ecto.Changeset.traverse_errors(invalid_changeset, fn {message, _opts} -> message end)

    assert "is invalid" in errors.role_target
  end

  test "group mapping requires exact source and role values" do
    changeset =
      GroupMapping.changeset(%GroupMapping{}, %{
        @valid_attrs
        | source_attribute: "",
          source_value: "",
          role_value: ""
      })

    refute changeset.valid?

    errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)

    assert "can't be blank" in errors.source_attribute
    assert "can't be blank" in errors.source_value
    assert "can't be blank" in errors.role_value
  end
end
