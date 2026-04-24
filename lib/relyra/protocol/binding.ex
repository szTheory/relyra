defmodule Relyra.Protocol.Binding do
  @moduledoc false

  alias Relyra.Error

  @spec encode_redirect(binary(), binary()) :: {:ok, map()} | {:error, Error.t()}
  def encode_redirect(authn_request_xml, relay_state)
      when is_binary(authn_request_xml) and authn_request_xml != "" and is_binary(relay_state) and
             relay_state != "" do
    {:ok,
     %{
       "SAMLRequest" => Base.encode64(authn_request_xml, padding: false),
       "RelayState" => relay_state
     }}
  end

  def encode_redirect(_authn_request_xml, _relay_state) do
    invalid_binding_payload("Redirect binding requires XML and relay state strings")
  end

  @spec decode_post(map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def decode_post(params, opts \\ [])

  def decode_post(params, opts) when is_map(params) do
    saml_response_key = Keyword.get(opts, :saml_response_key, "SAMLResponse")
    relay_state_key = Keyword.get(opts, :relay_state_key, "RelayState")

    with {:ok, encoded_response} <- fetch_binary(params, saml_response_key),
         {:ok, decoded_xml} <- decode_base64(encoded_response) do
      {:ok, %{response_xml: decoded_xml, relay_state: Map.get(params, relay_state_key)}}
    end
  end

  def decode_post(_params, _opts) do
    {:error, Error.new(:invalid_binding_payload, "POST binding payload must be a map")}
  end

  defp fetch_binary(params, key) do
    value = Map.get(params, key) || Map.get(params, to_string(key))

    case value do
      value when is_binary(value) and value != "" ->
        {:ok, value}

      _ ->
        invalid_binding_payload("SAMLResponse is required for HTTP-POST binding")
    end
  end

  defp decode_base64(value) do
    case Base.decode64(value, padding: false) do
      {:ok, decoded_xml} ->
        {:ok, decoded_xml}

      :error ->
        invalid_binding_payload("SAMLResponse must be valid base64 payload")
    end
  end

  defp invalid_binding_payload(message) do
    {:error, Error.new(:invalid_binding_payload, message)}
  end
end
