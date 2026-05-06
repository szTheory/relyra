defmodule Relyra.ConnectionTest do
  use ExUnit.Case, async: true

  alias Relyra.{Connection, ConnectionResolver, Error}

  defmodule MapResolver do
    @behaviour ConnectionResolver

    @impl true
    def resolve_connection(%{connection_id: connection_id}, _opts) do
      {:ok,
       %{
         id: "db-#{connection_id}",
         connection_id: connection_id,
         idp_entity_id: "https://idp.example.com",
         sp_entity_id: "https://sp.example.com",
         acs_url: "https://sp.example.com/acs",
         idp_sso_url: "https://idp.example.com/sso",
         idp_certificates: ["cert-a"]
       }}
    end
  end

  defmodule InvalidResolver do
    @behaviour ConnectionResolver

    @impl true
    def resolve_connection(_request_context, _opts), do: :bad_tuple
  end

  test "runtime connection keeps public connection_id distinct from internal id" do
    connection = %Connection{id: "db_pk_123", connection_id: "01JT6YXBK1Q3DNEJQY23WJ6TB2"}

    assert connection.id == "db_pk_123"
    assert connection.connection_id == "01JT6YXBK1Q3DNEJQY23WJ6TB2"
    refute connection.id == connection.connection_id
  end

  test "resolver normalizes canonical runtime snapshots onto the public struct" do
    assert {:ok, %Connection{} = connection} =
             ConnectionResolver.resolve_connection(
               %{connection_id: "conn_123"},
               connection_resolver: MapResolver
             )

    assert connection.connection_id == "conn_123"
    assert connection.idp_certificates == ["cert-a"]
    assert connection.cert_chain == ["cert-a"]
  end

  test "default resolver stays inside the bounded resolver taxonomy" do
    assert {:error, %Error{type: :resolver_misconfigured, details: details}} =
             Relyra.ConnectionResolver.Default.resolve_connection(%{}, [])

    assert details.reason == :adapter_unavailable
    assert details.operation == :resolve_connection
  end

  test "invalid adapter tuples fail with structured resolver errors" do
    assert {:error, %Error{type: :resolver_failed, details: details}} =
             ConnectionResolver.resolve_connection(%{connection_id: "conn_123"},
               connection_resolver: InvalidResolver
             )

    assert details.reason == :invalid_adapter_result
    assert details.operation == :resolve_connection
  end
end
