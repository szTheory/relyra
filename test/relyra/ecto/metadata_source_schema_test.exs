defmodule Relyra.Ecto.MetadataSourceSchemaTest do
  use ExUnit.Case, async: true

  alias Relyra.Ecto.MetadataSource

  test "metadata source changeset rejects missing provenance fields and non-https urls" do
    changeset = MetadataSource.changeset(%MetadataSource{}, %{url: "http://idp.example.com/metadata"})

    refute changeset.valid?

    errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)

    assert "can't be blank" in errors.connection_record_id
    assert "can't be blank" in errors.kind
    assert "can't be blank" in errors.registered_by
    assert "can't be blank" in errors.registered_reason
    assert "must be an HTTPS URL" in errors.url
  end
end
