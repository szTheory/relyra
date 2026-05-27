defmodule Relyra.Security.LogoutValidator do
  @moduledoc false

  alias Relyra.Error
  alias Relyra.Protocol.LogoutRequest
  alias Relyra.Protocol.LogoutResponse
  alias Relyra.Security.Signature
  alias Relyra.Security.XML.PureBeam
  alias Relyra.ReplayStore
  alias Relyra.Security.AlgorithmPolicy

  @spec validate_logout_request(binary(), map(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def validate_logout_request(raw_xml_or_query, connection, opts \\ []) do
    validate_logout(:request, raw_xml_or_query, connection, opts)
  end

  @spec validate_logout_response(binary(), map(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def validate_logout_response(raw_xml_or_query, connection, opts \\ []) do
    validate_logout(:response, raw_xml_or_query, connection, opts)
  end

  defp validate_logout(type, payload, connection, opts) do
    binding = Keyword.get(opts, :binding, :post)
    cert_chain = cert_chain(connection, opts)

    case binding do
      :post ->
        validate_post(type, payload, connection, cert_chain, opts)

      :redirect ->
        validate_redirect(type, payload, connection, cert_chain, opts)

      other ->
        {:error, Error.new(:invalid_binding, "Unsupported binding", %{binding: other})}
    end
  end

  defp validate_post(type, raw_xml, connection, cert_chain, opts) do
    with {:ok, parsed_doc} <- PureBeam.parse_safely(raw_xml, parse_opts(opts)),
         :ok <- require_xml_signature(parsed_doc),
         {:ok, _signed_node} <- Signature.verify(parsed_doc, connection, cert_chain, opts),
         {:ok, message} <- parse_message(type, parsed_doc),
         :ok <- check_replay(message, connection, opts),
         :ok <- check_status(type, message),
         :ok <- check_issuer(message, connection) do
      {:ok, message}
    end
  end

  defp require_xml_signature(%{signature_method: _}), do: :ok
  defp require_xml_signature(_) do
    {:error,
     Error.new(
       :missing_signature,
       "Signed XML material is missing required signature fields",
       %{
         missing: [:signature_method, :digest_method, :signed_candidates],
         actual: [],
         expected: [:signature_method, :digest_method, :signed_candidates]
       }
     )}
  end

  defp validate_redirect(type, raw_query, connection, cert_chain, opts) do
    with {:ok, query_parts} <- parse_raw_query(raw_query),
         {:ok, public_key} <- Signature.public_key_from_cert_chain(cert_chain),
         :ok <- verify_redirect(raw_query, query_parts, public_key, connection, opts),
         {:ok, deflated_b64} <- extract_payload(type, query_parts),
         {:ok, raw_xml} <- inflate_payload(deflated_b64),
         {:ok, parsed_doc} <- PureBeam.parse_safely(raw_xml, parse_opts(opts)),
         {:ok, message} <- parse_message(type, parsed_doc),
         :ok <- check_replay(message, connection, opts),
         :ok <- check_status(type, message),
         :ok <- check_issuer(message, connection) do
      {:ok, message}
    end
  end

  defp parse_message(:request, parsed_doc), do: LogoutRequest.from_parsed_doc(parsed_doc)
  defp parse_message(:response, parsed_doc), do: LogoutResponse.from_parsed_doc(parsed_doc)

  defp check_replay(message, connection, opts) do
    # Extract ID differently for request vs response
    id = Map.get(message, :id) || Map.get(message, :in_response_to)
    
    if is_nil(id) do
      {:error, Error.new(:missing_protocol_field, "Message ID is required for replay protection", %{})}
    else
      metadata = %{
        connection_id: expected_connection_id(connection),
        issuer: Map.get(message, :issuer)
      }
      
      ReplayStore.consume_replay_key(id, metadata, opts)
    end
  end

  defp check_status(:request, _message), do: :ok
  
  defp check_status(:response, message) do
    # LogoutResponse has a status to validate.
    status = Map.get(message, :status)
    Relyra.Protocol.Response.validate_status(status)
  end

  defp check_issuer(message, connection) do
    expected_issuer = Map.get(connection, :idp_entity_id) || Map.get(connection, :issuer)
    actual_issuer = Map.get(message, :issuer)

    if expected_issuer == actual_issuer do
      :ok
    else
      {:error,
       Error.new(
         :issuer_mismatch,
         "SAML message Issuer does not match connection configuration",
         %{
           expected: expected_issuer,
           actual: actual_issuer
         }
       )}
    end
  end

  defp verify_redirect(raw_query, query_parts, public_key, connection, opts) do
    sig_alg = query_parts["SigAlg"]
    signature_b64 = query_parts["Signature"]

    if is_nil(sig_alg) or is_nil(signature_b64) do
      {:error, Error.new(:missing_signature, "Redirect query is missing SigAlg or Signature parameters", %{})}
    else
      policy = Keyword.get(opts, :algorithm_policy, AlgorithmPolicy.default())
      
      with :ok <- evaluate_policy(AlgorithmPolicy.enforce_signature_method(policy, sig_alg), connection),
           {:ok, digest_atom} <- signing_digest_atom(sig_alg, connection),
           {:ok, signature_bytes} <- decode_signature(signature_b64) do
        
        # We need the raw query BEFORE the Signature parameter.
        # It's usually everything before &Signature=
        raw_signed_query = extract_signed_query(raw_query)
        
        Signature.verify_redirect_signature(raw_signed_query, digest_atom, signature_bytes, public_key)
      end
    end
  end

  defp extract_signed_query(raw_query) do
    case String.split(raw_query, "&Signature=") do
      [signed_part, _sig_part] -> signed_part
      _ -> raw_query # fallback, but verify_redirect_signature will fail
    end
  end

  defp decode_signature(b64) do
    case Base.decode64(b64) do
      {:ok, bytes} -> {:ok, bytes}
      :error -> {:error, Error.new(:invalid_signature, "Invalid base64 signature", %{})}
    end
  end

  defp signing_digest_atom(signature_method, connection) do
    case AlgorithmPolicy.signing_digest_atom(signature_method) do
      {:ok, atom} ->
        {:ok, atom}

      {:error, error_type} ->
        {:error,
         Error.new(
           error_type,
           "Unsupported signature algorithm in redirect binding",
           %{connection_id: expected_connection_id(connection), signature_method: signature_method}
         )}
    end
  end

  defp evaluate_policy(:ok, _connection), do: :ok
  defp evaluate_policy(%Error{} = error, connection) do
    {:error, Error.new(error.type, error.message, Map.put(error.details, :connection_id, expected_connection_id(connection)))}
  end

  defp parse_raw_query(raw_query) do
    parts = URI.decode_query(raw_query)
    {:ok, parts}
  end

  defp extract_payload(:request, query_parts) do
    case Map.get(query_parts, "SAMLRequest") do
      nil -> {:error, Error.new(:missing_protocol_field, "Missing SAMLRequest parameter", %{})}
      val -> {:ok, val}
    end
  end

  defp extract_payload(:response, query_parts) do
    case Map.get(query_parts, "SAMLResponse") do
      nil -> {:error, Error.new(:missing_protocol_field, "Missing SAMLResponse parameter", %{})}
      val -> {:ok, val}
    end
  end

  defp inflate_payload(b64) do
    # Try with padding, then without
    decoded = case Base.decode64(b64) do
      {:ok, bytes} -> {:ok, bytes}
      :error -> Base.decode64(b64, padding: false)
    end

    case decoded do
      {:ok, deflated} ->
        z = :zlib.open()
        try do
          :ok = :zlib.inflateInit(z, -15)
          {:ok, :zlib.inflate(z, deflated) |> IO.iodata_to_binary()}
        rescue
          _ -> {:error, Error.new(:invalid_binding_payload, "Failed to inflate deflate payload", %{})}
        after
          :zlib.close(z)
        end
      :error ->
        {:error, Error.new(:invalid_binding_payload, "Invalid base64 payload", %{})}
    end
  end

  defp parse_opts(opts), do: Keyword.take(opts, [:max_bytes])

  defp cert_chain(connection, opts) do
    Keyword.get(opts, :cert_chain) || Map.get(connection, :idp_certificates) ||
      Map.get(connection, :cert_chain) || []
  end

  defp expected_connection_id(connection) do
    Map.get(connection, :id) || Map.get(connection, :connection_id)
  end
end
