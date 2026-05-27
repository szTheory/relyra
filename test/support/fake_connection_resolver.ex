defmodule Relyra.TestSupport.FakeConnectionResolver do
  @moduledoc false
  @behaviour Relyra.ConnectionResolver

  alias Relyra.Connection

  def resolve_connection(%{connection_id: "valid"}, _opts) do
    {:ok,
     %Connection{
       id: "valid",
       connection_id: "valid",
       idp_sso_url: "https://idp.example.com/sso",
       sp_entity_id: "https://sp.example.com",
       idp_entity_id: "https://idp.example.com",
       acs_url: "https://sp.example.com/acs",
       idp_certificates: ["fake-cert"],
       cert_chain: ["fake-cert"]
     }}
  end

  def resolve_connection(%{connection_id: "valid_signed"}, _opts) do
    {:ok,
     %Connection{
       id: "valid_signed",
       connection_id: "valid_signed",
       idp_sso_url: "https://idp.example.com/sso",
       sp_entity_id: "https://sp.example.com",
       idp_entity_id: "https://idp.example.com",
       acs_url: "https://sp.example.com/acs",
       idp_certificates: ["fake-cert"],
       cert_chain: ["fake-cert"],
       sign_authn_requests: true,
       signed_request_encoding: :rfc3986_upper
     }}
  end

  def resolve_connection(_, _opts) do
    {:error,
     Relyra.Error.new(:connection_unavailable, "Unknown connection", %{
       reason: :not_found,
       operation: :resolve_connection
     })}
  end
end
