defmodule Relyra.Protocol.Binding do
  @moduledoc false

  alias Relyra.Error
  alias Relyra.Security.Signature

  defp deflate_xml(xml) when is_binary(xml) do
    z = :zlib.open()

    try do
      :ok = :zlib.deflateInit(z, :default, :deflated, -15, 8, :default)
      iodata = :zlib.deflate(z, xml, :finish)
      :ok = :zlib.deflateEnd(z)
      IO.iodata_to_binary(iodata)
    after
      :zlib.close(z)
    end
  end

  @spec encode_redirect(binary(), binary() | nil, keyword()) :: {:ok, map()} | {:error, Error.t()}
  def encode_redirect(xml, relay_state, opts \\ [])

  def encode_redirect(xml, relay_state, opts)
      when is_binary(xml) and xml != "" and is_list(opts) do
    cond do
      relay_state == nil or (is_binary(relay_state) and relay_state != "") ->
        do_encode_redirect(xml, relay_state, opts)

      true ->
        invalid_binding_payload("Redirect binding requires XML and relay state strings")
    end
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

  defp do_encode_redirect(xml, relay_state, opts) do
    key = if Keyword.get(opts, :type) == :response, do: "SAMLResponse", else: "SAMLRequest"
    deflated = deflate_xml(xml)
    b64 = Base.encode64(deflated)
    sign = Keyword.get(opts, :sign, false)
    encoding = Keyword.get(opts, :encoding, :rfc3986_upper)

    if sign do
      signature_method =
        Keyword.get(opts, :signature_method, "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")

      signing_opts =
        opts
        |> Keyword.take([:signing_key_pem, :connection_id])
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)

      octets = signed_octets(key, b64, relay_state, signature_method, encoding)

      with {:ok, signature_url_encoded} <-
             Signature.sign_redirect_query(octets, signature_method, signing_opts) do
        signature_url_encoded =
          if encoding == :adfs_lower do
            lowercase_hex(signature_url_encoded)
          else
            signature_url_encoded
          end

        {:ok, %{redirect_query: octets <> "&Signature=" <> signature_url_encoded}}
      end
    else
      {:ok, unsigned_params(key, b64, relay_state)}
    end
  end

  defp unsigned_params(key, b64, nil), do: %{key => b64}
  defp unsigned_params(key, b64, relay_state), do: %{key => b64, "RelayState" => relay_state}

  defp signed_octets(key, b64, relay_state, signature_method, encoding) do
    [key <> "=" <> encode_value(b64, encoding)]
    |> maybe_append_relay_state(relay_state, encoding)
    |> Kernel.++(["SigAlg=" <> encode_value(signature_method, encoding)])
    |> Enum.join("&")
  end

  defp maybe_append_relay_state(parts, nil, _encoding), do: parts

  defp maybe_append_relay_state(parts, relay_state, encoding),
    do: parts ++ ["RelayState=" <> encode_value(relay_state, encoding)]

  defp encode_value(value, :adfs_lower), do: value |> URI.encode_www_form() |> lowercase_hex()
  defp encode_value(value, _encoding), do: URI.encode_www_form(value)

  defp lowercase_hex(encoded) do
    Regex.replace(~r/%[0-9A-F]{2}/, encoded, &String.downcase/1)
  end
end
