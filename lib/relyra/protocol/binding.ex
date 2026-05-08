defmodule Relyra.Protocol.Binding do
  @moduledoc false

  alias Relyra.Error

  @spec encode_redirect(binary(), binary(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def encode_redirect(xml, relay_state, opts \\ [])

  def encode_redirect(xml, relay_state, opts)
      when is_binary(xml) and xml != "" and is_binary(relay_state) and
             relay_state != "" do
    key = if Keyword.get(opts, :type) == :response, do: "SAMLResponse", else: "SAMLRequest"

    {:ok,
     %{
       key => Base.encode64(xml, padding: false),
       "RelayState" => relay_state
     }}
  end

  def encode_redirect(_xml, _relay_state, _opts) do
    invalid_binding_payload("Redirect binding requires XML and relay state strings")
  end

  @spec decode_redirect(map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def decode_redirect(params, opts \\ [])

  def decode_redirect(params, opts) when is_map(params) do
    metadata = %{binding: :redirect, flow: :sp_initiated}

    Relyra.Telemetry.span([:response, :decode], metadata, fn ->
      result = do_decode_redirect(params, opts)

      case result do
        {:ok, %{response_xml: xml} = decoded} ->
          encoded = fetch_encoded_redirect(params) || ""

          {{:ok, decoded},
           Map.merge(metadata, %{
             outcome: :ok,
             xml_bytes: byte_size(xml),
             base64_bytes: byte_size(encoded)
           })}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  def decode_redirect(_params, _opts) do
    {:error, Error.new(:invalid_binding_payload, "Redirect binding payload must be a map")}
  end

  defp do_decode_redirect(params, opts) do
    relay_state_key = Keyword.get(opts, :relay_state_key, "RelayState")

    with {:ok, encoded_value} <- fetch_redirect_payload(params),
         {:ok, decoded_xml} <- decode_base64(encoded_value) do
      {:ok, %{response_xml: decoded_xml, relay_state: Map.get(params, relay_state_key)}}
    end
  end

  defp fetch_encoded_redirect(params) do
    Map.get(params, "SAMLRequest") || Map.get(params, "SAMLResponse")
  end

  defp fetch_redirect_payload(params) do
    case fetch_encoded_redirect(params) do
      value when is_binary(value) and value != "" ->
        {:ok, value}

      _ ->
        invalid_binding_payload(
          "SAMLRequest or SAMLResponse is required for HTTP-Redirect binding"
        )
    end
  end

  @spec decode_post(map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def decode_post(params, opts \\ [])

  def decode_post(params, opts) when is_map(params) do
    metadata = %{binding: :post, flow: :sp_initiated}

    Relyra.Telemetry.span([:response, :decode], metadata, fn ->
      result = do_decode_post(params, opts)

      case result do
        {:ok, %{response_xml: xml} = decoded} ->
          saml_response_key = Keyword.get(opts, :saml_response_key, "SAMLResponse")

          encoded_response =
            Map.get(params, saml_response_key) || Map.get(params, to_string(saml_response_key))

          {{:ok, decoded},
           Map.merge(metadata, %{
             outcome: :ok,
             xml_bytes: byte_size(xml),
             base64_bytes: byte_size(encoded_response || "")
           })}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  def decode_post(_params, _opts) do
    {:error, Error.new(:invalid_binding_payload, "POST binding payload must be a map")}
  end

  defp do_decode_post(params, opts) do
    saml_response_key = Keyword.get(opts, :saml_response_key, "SAMLResponse")
    relay_state_key = Keyword.get(opts, :relay_state_key, "RelayState")

    with {:ok, encoded_response} <- fetch_binary(params, saml_response_key),
         {:ok, decoded_xml} <- decode_base64(encoded_response) do
      {:ok, %{response_xml: decoded_xml, relay_state: Map.get(params, relay_state_key)}}
    end
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
    # Try with padding, then without
    case Base.decode64(value) do
      {:ok, decoded_xml} ->
        {:ok, decoded_xml}

      :error ->
        case Base.decode64(value, padding: false) do
          {:ok, decoded_xml} -> {:ok, decoded_xml}
          :error -> invalid_binding_payload("SAMLResponse must be valid base64 payload")
        end
    end
  end

  defp invalid_binding_payload(message) do
    {:error, Error.new(:invalid_binding_payload, message)}
  end
end
