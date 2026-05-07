defmodule Relyra.Ecto.AttributeMappingSchemaTest do
  use ExUnit.Case, async: true

  alias Relyra.Ecto.AttributeMapping

  @valid_attrs %{
    connection_record_id: Ecto.UUID.generate(),
    source_attribute: "mail",
    target_field: :email,
    multivalue_strategy: :first
  }

  test "attribute mapping changeset rejects missing required mapping fields" do
    changeset = AttributeMapping.changeset(%AttributeMapping{}, %{})

    refute changeset.valid?

    errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)

    assert "can't be blank" in errors.connection_record_id
    assert "can't be blank" in errors.source_attribute
    assert "can't be blank" in errors.target_field
    assert "can't be blank" in errors.multivalue_strategy
  end

  test "attribute mapping target field and multivalue strategy stay within the bounded phase contract" do
    valid_changeset = AttributeMapping.changeset(%AttributeMapping{}, @valid_attrs)

    assert valid_changeset.valid?

    invalid_changeset =
      AttributeMapping.changeset(%AttributeMapping{}, %{
        connection_record_id: Ecto.UUID.generate(),
        source_attribute: "department",
        target_field: :department,
        multivalue_strategy: :join
      })

    refute invalid_changeset.valid?

    errors = Ecto.Changeset.traverse_errors(invalid_changeset, fn {message, _opts} -> message end)

    assert "is invalid" in errors.target_field
    assert "is invalid" in errors.multivalue_strategy
  end

  test "attribute mapping stays in exact-name scope without transform or expression fields" do
    changeset = AttributeMapping.changeset(%AttributeMapping{}, @valid_attrs)

    assert changeset.valid?

    fields = AttributeMapping.__schema__(:fields)

    assert :source_attribute in fields
    assert :target_field in fields
    assert :multivalue_strategy in fields
    refute :regex in fields
    refute :script in fields
    refute :expression in fields
    refute :transform in fields
  end

  test "attribute mapping only accepts explicit multivalue strategies" do
    allowed_changesets =
      Enum.map([:first, :all], fn strategy ->
        AttributeMapping.changeset(
          %AttributeMapping{},
          Map.put(@valid_attrs, :multivalue_strategy, strategy)
        )
      end)

    assert Enum.all?(allowed_changesets, & &1.valid?)
  end
end
