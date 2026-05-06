defmodule Relyra.Ecto.MetadataRevisionSchemaTest do
  use ExUnit.Case, async: true

  alias Relyra.Ecto.MetadataRevision

  test "metadata revision changeset rejects missing required provenance fields" do
    changeset = MetadataRevision.changeset(%MetadataRevision{}, %{})

    refute changeset.valid?

    errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)

    assert "can't be blank" in errors.connection_record_id
    assert "can't be blank" in errors.source_kind
    assert "can't be blank" in errors.trigger
    assert "can't be blank" in errors.outcome
    assert "can't be blank" in errors.trust_summary
  end
end
