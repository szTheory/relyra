defmodule Relyra.TestSupport.KeycloakAdoption do
  @moduledoc false

  @realm "relyra-adoption"
  @connection_id "keycloak"

  def base_url! do
    System.get_env("KEYCLOAK_BASE_URL") ||
      raise "KEYCLOAK_BASE_URL is required for external IdP adoption tests"
  end

  def wait_for_ready!(base_url, attempts \\ 60) do
    url = Path.join(base_url, "realms/#{@realm}/.well-known/openid-configuration")

    Enum.reduce_while(1..attempts, :error, fn attempt, _acc ->
      case Req.get(url, receive_timeout: 5_000, retry: false) do
        {:ok, %{status: 200}} ->
          {:halt, :ok}

        _ when attempt == attempts ->
          {:halt, {:error, :timeout}}

        _ ->
          Process.sleep(1_000)
          {:cont, :error}
      end
    end)
    |> case do
      :ok -> :ok
      {:error, :timeout} -> raise "Keycloak did not become ready at #{base_url}"
    end
  end

  def fetch_signing_cert_pem!(base_url) do
    descriptor_url = Path.join(base_url, "realms/#{@realm}/protocol/saml/descriptor")

    {:ok, %{status: 200, body: body}} =
      Req.get(descriptor_url, receive_timeout: 10_000, retry: false)

    case Regex.run(~r/<(?:ds:)?X509Certificate>([^<]+)<\/(?:ds:)?X509Certificate>/, body) do
      [_, cert_b64] ->
        cert_der = Base.decode64!(String.replace(cert_b64, ~r/\s+/, ""))

        [
          :public_key.pem_encode([{:Certificate, cert_der, :not_encrypted}])
          |> IO.iodata_to_binary()
        ]

      _ ->
        raise "unable to parse signing certificate from Keycloak SAML descriptor"
    end
  end

  def build_connection!(base_url, cert_chain) do
    fixture = load_fixture!()

    idp_entity_id = Path.join(base_url, "realms/#{@realm}")
    idp_sso_url = Path.join(base_url, "realms/#{@realm}/protocol/saml")

    %Relyra.Connection{
      id: @connection_id,
      connection_id: @connection_id,
      sp_entity_id: fixture["sp_entity_id"],
      acs_url: fixture["acs_url"],
      idp_sso_url: idp_sso_url,
      idp_entity_id: idp_entity_id,
      idp_certificates: cert_chain,
      cert_chain: cert_chain,
      allow_idp_initiated?: false,
      require_signed_assertions?: true,
      require_signed_response?: true,
      name_id_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
    }
  end

  def start_login!(connection, opts) do
    relay_context = %{return_to: "/welcome"}

    case Relyra.start_login(connection, relay_context, opts) do
      {:ok, login} -> login
      {:error, %Relyra.Error{} = error} -> raise error.message
    end
  end

  def fetch_saml_response!(base_url, connection, login, username, password) do
    sso_url = build_sso_url(connection.idp_sso_url, login)

    {:ok, login_page} =
      Req.get(sso_url,
        receive_timeout: 15_000,
        retry: false,
        redirect: false
      )

    if login_page.status not in 200..399 do
      raise "unexpected Keycloak SSO status #{login_page.status}"
    end

    form = extract_form!(base_url, login_page.body)

    {:ok, auth_response} =
      Req.post(form.action,
        form: Map.merge(form.fields, %{"username" => username, "password" => password}),
        receive_timeout: 15_000,
        retry: false,
        redirect: false
      )

    extract_saml_post!(auth_response)
  end

  defp build_sso_url(idp_sso_url, %{redirect_params: params}) when is_map(params) do
    idp_sso_url <> "?" <> URI.encode_query(params)
  end

  defp build_sso_url(idp_sso_url, %{redirect_query: query}) when is_binary(query) do
    idp_sso_url <> "?" <> query
  end

  defp extract_form!(base_url, html) when is_binary(html) do
    action =
      case Regex.run(~r/<form[^>]+action="([^"]+)"/, html) do
        [_, relative] -> relative
        _ -> raise "unable to locate Keycloak login form action"
      end

    fields =
      Regex.scan(~r/<input[^>]+name="([^"]+)"[^>]*value="([^"]*)"/, html)
      |> Map.new(fn [_, name, value] -> {name, value} end)

    absolute_action =
      if String.starts_with?(action, "http") do
        action
      else
        URI.merge(base_url <> "/", action) |> URI.to_string()
      end

    %{action: absolute_action, fields: fields}
  end

  defp extract_saml_post!(%{status: status, body: body}) when status in 200..399 do
    cond do
      saml = extract_hidden_field(body, "SAMLResponse") ->
        relay_state = extract_hidden_field(body, "RelayState") || ""
        {saml, relay_state}

      true ->
        raise "Keycloak auth response did not contain SAMLResponse (status=#{status})"
    end
  end

  defp extract_hidden_field(html, name) do
    case Regex.run(~r/name="#{name}"[^>]*value="([^"]*)"/, html) do
      [_, value] -> value
      _ -> nil
    end
  end

  defp load_fixture! do
    Path.expand("test/adoption/keycloak/fixtures/connection.json", File.cwd!())
    |> File.read!()
    |> Jason.decode!()
  end
end
