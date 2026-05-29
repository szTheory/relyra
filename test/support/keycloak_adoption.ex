defmodule Relyra.TestSupport.KeycloakAdoption do
  @moduledoc false

  @realm "relyra-adoption"
  @connection_id "keycloak"
  @redirect_binding "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"

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

    opts =
      opts
      |> Keyword.put(:protocol_binding, @redirect_binding)
      |> Keyword.put_new(:now, DateTime.utc_now())

    case Relyra.start_login(connection, relay_context, opts) do
      {:ok, login} -> login
      {:error, %Relyra.Error{} = error} -> raise error.message
    end
  end

  def fetch_saml_response!(base_url, connection, login, username, password) do
    sso_url = build_sso_url(connection.idp_sso_url, login)

    {:ok, login_page} =
      Req.get(sso_url, redirect: false, receive_timeout: 15_000, retry: false)

    if login_page.status < 200 or login_page.status >= 500 do
      body = String.slice(login_page.body || "", 0, 500)

      raise "unexpected Keycloak SSO status #{login_page.status} from #{sso_url}: #{body}"
    end

    form = extract_form!(base_url, login_page.body)
    cookie = cookie_header(login_page)

    {:ok, auth_response} =
      Req.post(form.action,
        redirect: false,
        receive_timeout: 15_000,
        retry: false,
        headers: [{"cookie", cookie}],
        form: Map.merge(form.fields, %{"username" => username, "password" => password})
      )

    extract_saml_post!(auth_response)
  end

  defp build_sso_url(idp_sso_url, %{redirect_query: redirect_query})
       when is_binary(redirect_query) do
    separator = if String.contains?(idp_sso_url, "?"), do: "&", else: "?"
    idp_sso_url <> separator <> redirect_query
  end

  defp build_sso_url(idp_sso_url, %{redirect_params: redirect_params})
       when is_map(redirect_params) do
    uri = URI.parse(idp_sso_url)
    existing_query = URI.decode_query(uri.query || "")
    new_query = Map.merge(existing_query, redirect_params)

    uri
    |> Map.put(:query, URI.encode_query(new_query))
    |> URI.to_string()
  end

  defp build_sso_url(_idp_sso_url, login) do
    raise "start_login/3 returned no redirect payload: #{inspect(Map.keys(login))}"
  end

  defp extract_form!(base_url, html) when is_binary(html) do
    {action, form_html} =
      case Regex.run(
             ~r/<form id="kc-form-login"[^>]*action="([^"]+)"[^>]*>(.*?)<\/form>/s,
             html
           ) do
        [_, action, inner] ->
          {action, inner}

        _ ->
          case Regex.run(~r/<form[^>]+action="([^"]+)"[^>]*>(.*?)<\/form>/s, html) do
            [_, action, inner] -> {action, inner}
            _ -> raise "unable to locate Keycloak login form"
          end
      end

    fields =
      form_html
      |> input_fields_with_values()
      |> Map.merge(input_fields_without_values(form_html))

    absolute_action =
      action
      |> String.replace("&amp;", "&")
      |> then(fn decoded_action ->
        if String.starts_with?(decoded_action, "http") do
          decoded_action
        else
          URI.merge(base_url <> "/", decoded_action) |> URI.to_string()
        end
      end)

    %{action: absolute_action, fields: fields}
  end

  defp input_fields_with_values(form_html) do
    ~r/<input[^>]+name="([^"]+)"[^>]+value="([^"]*)"[^>]*>/
    |> Regex.scan(form_html)
    |> Map.new(fn [_, name, value] -> {name, value} end)
  end

  defp input_fields_without_values(form_html) do
    with_values = input_fields_with_values(form_html)

    ~r/<input[^>]+name="([^"]+)"[^>]*\/?>/
    |> Regex.scan(form_html)
    |> Map.new(fn [_, name] -> {name, ""} end)
    |> Map.drop(Map.keys(with_values))
  end

  defp cookie_header(%{headers: headers}) when is_map(headers) do
    headers
    |> Enum.filter(fn {name, _} -> String.downcase(name) == "set-cookie" end)
    |> Enum.flat_map(fn {_, values} -> List.wrap(values) end)
    |> Enum.map(fn value ->
      value
      |> String.split(";", parts: 2)
      |> hd()
      |> String.trim()
    end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("; ")
  end

  defp extract_saml_post!(%{status: status, headers: headers, body: body})
       when status in 200..399 do
    cond do
      saml = extract_hidden_field(body, "SAMLResponse") ->
        relay_state = extract_hidden_field(body, "RelayState") || ""
        {saml, relay_state}

      true ->
        case extract_saml_from_location!(headers) do
          {saml, relay_state} ->
            {saml, relay_state}

          nil ->
            snippet = String.slice(body || "", 0, 500)

            raise "Keycloak auth response did not contain SAMLResponse (status=#{status}): #{snippet}"
        end
    end
  end

  defp extract_saml_post!(%{status: status, body: body}) do
    snippet = String.slice(body || "", 0, 500)
    raise "Keycloak auth response failed (status=#{status}): #{snippet}"
  end

  defp extract_hidden_field(html, name) when is_binary(html) do
    case Regex.run(~r/name="#{name}"[^>]*value="([^"]*)"/, html) do
      [_, value] -> value
      _ -> nil
    end
  end

  defp extract_hidden_field(_html, _name), do: nil

  defp extract_saml_from_location!(headers) when is_map(headers) do
    location =
      headers
      |> Enum.find_value(fn {name, value} ->
        if String.downcase(name) == "location" do
          value |> List.wrap() |> List.first()
        end
      end)

    with loc when is_binary(loc) <- location,
         %URI{query: query} <- URI.parse(loc),
         query when is_binary(query) <- query,
         params <- URI.decode_query(query),
         saml when is_binary(saml) and saml != "" <- Map.get(params, "SAMLResponse") do
      {normalize_saml_response_for_acs_post!(saml), Map.get(params, "RelayState", "")}
    else
      _ -> nil
    end
  end

  defp normalize_saml_response_for_acs_post!(encoded) when is_binary(encoded) do
    decoded =
      case Base.decode64(encoded) do
        {:ok, bin} -> bin
        :error -> Base.decode64!(encoded, padding: false)
      end

    xml =
      if String.starts_with?(decoded, "<") do
        decoded
      else
        inflate_deflated!(decoded)
      end

    Base.encode64(xml)
  end

  defp inflate_deflated!(deflated) do
    z = :zlib.open()

    try do
      :ok = :zlib.inflateInit(z, -15)
      :zlib.inflate(z, deflated) |> IO.iodata_to_binary()
    after
      :zlib.close(z)
    end
  end

  defp load_fixture! do
    Path.expand("test/adoption/keycloak/fixtures/connection.json", File.cwd!())
    |> File.read!()
    |> Jason.decode!()
  end
end
