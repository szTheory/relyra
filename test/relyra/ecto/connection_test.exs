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

  test "default signed_request_encoding is nil" do
    connection = %Connection{}
    assert connection.signed_request_encoding == nil
  end

  test "draft_changeset accepts signed_request_encoding atoms" do
    changeset = Connection.draft_changeset(%Connection{}, %{signed_request_encoding: :adfs_lower})
    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :signed_request_encoding) == :adfs_lower

    changeset =
      Connection.draft_changeset(%Connection{}, %{signed_request_encoding: :rfc3986_upper})

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :signed_request_encoding) == :rfc3986_upper
  end

  test "draft_changeset accepts nil signed_request_encoding" do
    changeset = Connection.draft_changeset(%Connection{}, %{signed_request_encoding: nil})
    assert changeset.valid?
  end

  test "draft_changeset rejects invalid signed_request_encoding values" do
    changeset = Connection.draft_changeset(%Connection{}, %{signed_request_encoding: :sha1})
    refute changeset.valid?
    assert changeset.errors[:signed_request_encoding]

    changeset = Connection.draft_changeset(%Connection{}, %{signed_request_encoding: "garbage"})
    refute changeset.valid?
    assert changeset.errors[:signed_request_encoding]
  end

  test "update_changeset accepts and rejects signed_request_encoding values" do
    changeset =
      Connection.update_changeset(%Connection{}, %{signed_request_encoding: :adfs_lower})

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :signed_request_encoding) == :adfs_lower

    changeset = Connection.update_changeset(%Connection{}, %{signed_request_encoding: :sha1})
    refute changeset.valid?
    assert changeset.errors[:signed_request_encoding]
  end
end
