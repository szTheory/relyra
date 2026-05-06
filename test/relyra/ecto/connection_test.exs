defmodule Relyra.Ecto.ConnectionTest do
  use ExUnit.Case, async: true

  alias Relyra.Ecto.Connection

  test "default allow_idp_initiated is false" do
    connection = %Connection{}
    assert connection.allow_idp_initiated == false
  end

  test "draft_changeset allows setting allow_idp_initiated" do
    changeset = Connection.draft_changeset(%Connection{}, %{allow_idp_initiated: true})
    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :allow_idp_initiated) == true
  end

  test "update_changeset allows updating allow_idp_initiated" do
    changeset = Connection.update_changeset(%Connection{}, %{allow_idp_initiated: true})
    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :allow_idp_initiated) == true
  end
end
