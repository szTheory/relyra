defmodule Relyra.TestSupport.FakeConnectionResolver do
  @moduledoc false
  @behaviour Relyra.ConnectionResolver
  
  def resolve_connection(%{connection_id: "valid"}, _opts) do
    {:ok, %{
      id: "valid",
      connection_id: "valid",
      idp_sso_url: "https://idp.example.com/sso",
      sp_entity_id: "https://sp.example.com",
      idp_entity_id: "https://idp.example.com",
      acs_url: "https://sp.example.com/acs",
      cert_chain: ["fake-cert"]
    }}
  end
  
  def resolve_connection(_, _opts) do
    {:error, Relyra.Error.new(:unknown_connection, "Unknown connection")}
  end
end
