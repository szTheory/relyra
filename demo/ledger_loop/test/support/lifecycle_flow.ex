defmodule LedgerLoop.TestSupport.LifecycleFlow do
  @moduledoc """
  Drives an SP-initiated SAML login through LedgerLoop's real Phoenix routes.
  """

  import Phoenix.ConnTest

  alias LedgerLoop.Demo.Fixtures
  alias LedgerLoop.FakeIdP.Signer

  @endpoint LedgerLoopWeb.Endpoint

  def start_login(connection_id, issuer, subject, signer_options \\ []) do
    connection = Enum.find(Fixtures.relyra_connections(), &(&1.connection_id == connection_id))
    acs_path = "/saml/#{connection_id}/acs"
    login_conn = get(build_conn(), "/saml/#{connection_id}/login")
    location = login_conn |> Plug.Conn.get_resp_header("location") |> List.first()
    idp_uri = URI.parse(location)
    idp_params = URI.decode_query(idp_uri.query || "")
    relay_state = Map.fetch!(idp_params, "RelayState")
    saml_request = Map.fetch!(idp_params, "SAMLRequest")

    idp_login =
      get(build_conn(), "/fake_idp/login", %{
        "SAMLRequest" => saml_request,
        "RelayState" => relay_state
      })

    request_id = extract_hidden_field(response(idp_login, 200), "in_response_to")

    signer_opts =
      Keyword.merge(
        [
          issuer: issuer,
          destination: connection.acs_url,
          recipient: connection.acs_url,
          audience: connection.sp_entity_id,
          name_id: subject,
          in_response_to: request_id
        ],
        signer_options
      )

    %{
      acs_path: acs_path,
      acs_url: connection.acs_url,
      connection: connection,
      idp_login: idp_login,
      login_conn: login_conn,
      relay_state: relay_state,
      request_id: request_id,
      saml_response: Signer.signed_response(signer_opts)
    }
  end

  def post_acs(flow, saml_response \\ nil) do
    post(build_conn(), flow.acs_path, %{
      "SAMLResponse" => saml_response || flow.saml_response,
      "RelayState" => flow.relay_state
    })
  end

  defp extract_hidden_field(html, name) do
    case Regex.run(~r/name="#{Regex.escape(name)}" value="([^"]*)"/, html) do
      [_, value] -> value
      nil -> nil
    end
  end
end
