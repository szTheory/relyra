# Maintainer-only headless FakeIdP round trip (excluded from Hex package).
# Run from repo root: MIX_ENV=test mix run examples/quickstart.exs

unless Code.ensure_loaded?(Relyra.TestSupport.FakeIdP) do
  Mix.raise("""
  examples/quickstart.exs must run inside the Relyra repo with MIX_ENV=test so \
  Relyra.TestSupport is compiled (maintainer CI lane: mix ci.demo).
  """)
end

Mix.Task.run("app.start")

cert = Relyra.TestSupport.XmldsigSigner.self_signed_cert_pem()

connection = %Relyra.Connection{
  id: "quickstart",
  connection_id: "quickstart",
  sp_entity_id: "https://sp.example.com/metadata",
  acs_url: "https://sp.example.com/saml/acs",
  idp_sso_url: "https://idp.example.com/sso",
  idp_entity_id: "https://idp.example.com/metadata",
  idp_certificates: [cert],
  cert_chain: [cert],
  allow_idp_initiated?: false,
  require_signed_assertions?: true,
  require_signed_response?: true
}

Application.put_env(:relyra, :quickstart_connection, connection)

defmodule QuickstartResolver do
  @behaviour Relyra.ConnectionResolver

  @impl true
  def resolve_connection(%{connection_id: "quickstart"}, _opts) do
    {:ok, Application.fetch_env!(:relyra, :quickstart_connection)}
  end

  def resolve_connection(_request_context, _opts) do
    {:error,
     Relyra.Error.new(:connection_unavailable, "Unknown quickstart connection", %{
       reason: :not_found,
       operation: :resolve_connection
     })}
  end
end

relay_state = "rs_quickstart_#{System.unique_integer([:positive])}"
request_id = "id_quickstart_#{System.unique_integer([:positive])}"

signed_b64 =
  Relyra.TestSupport.FakeIdP.build_response(
    subject: "quickstart@example.com",
    audience: connection.sp_entity_id,
    destination: connection.acs_url,
    recipient: connection.acs_url,
    in_response_to: request_id,
    name_id: "quickstart@example.com"
  )
  |> Relyra.TestSupport.FakeIdP.sign()

response_xml = Base.decode64!(signed_b64, padding: false)

request_intent = %{
  request_id: request_id,
  in_response_to: request_id,
  relay_state: relay_state,
  connection_id: connection.connection_id,
  sp_entity_id: connection.sp_entity_id,
  acs_url: connection.acs_url,
  destination: connection.acs_url,
  recipient: connection.acs_url,
  return_to: "/welcome"
}

opts = [
  relay_state: relay_state,
  connection: connection,
  resolved_connection: connection,
  connection_resolver: QuickstartResolver,
  request_store: Relyra.TestSupport.NoopRequestStore,
  replay_store: Relyra.TestSupport.NoopReplayStore,
  request_intent: request_intent
]

case Relyra.consume_response(response_xml, request_intent, opts) do
  {:ok, %{principal: %{name_id: name_id}}} ->
    IO.puts("quickstart: verified SAML login for #{name_id}")

  {:error, %Relyra.Error{} = error} ->
    Mix.raise("quickstart failed: #{error.type} — #{error.message}")
end
