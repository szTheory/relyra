defmodule Relyra do
  @moduledoc """
  Public entry points for strict-by-default SAML protocol flows.
  """

  alias Relyra.ConnectionResolver
  alias Relyra.Error
  alias Relyra.Protocol.AuthnRequest
  alias Relyra.Protocol.Binding
  alias Relyra.Protocol.ValidationPipeline
  alias Relyra.ReplayStore
  alias Relyra.RequestStore
  alias Relyra.Security.RelayState

  @default_request_intent_ttl_seconds 300

  # Verification anchor: def start_login(connection, relay_context, opts \ [])
  @spec start_login(map(), map(), keyword()) :: {:ok, map()} | {:error, Relyra.Error.t()}
  def start_login(connection, relay_context, opts \\ []) do
    with {:ok, request_fields} <- AuthnRequest.build(connection, relay_context, opts),
         request_id <- Map.fetch!(request_fields, :id),
         authn_request_xml <- AuthnRequest.to_xml(request_fields),
         {:ok, relay_state} <-
           RelayState.issue(Map.put(relay_context, :request_id, request_id), opts),
         issued_at <- intent_issued_at(opts),
         expires_at <- intent_expires_at(issued_at, opts),
         intent <-
           build_request_intent(request_id, relay_state, connection, issued_at, expires_at),
         :ok <- persist_request_intent(relay_state, intent, opts),
         {:ok, redirect_params} <- Binding.encode_redirect(authn_request_xml, relay_state) do
      {:ok,
       %{
         request_id: request_id,
         authn_request: authn_request_xml,
         relay_state: relay_state,
         redirect_params: redirect_params
       }}
    end
  end

  @doc """
  Consume an ACS response using strict request correlation.

  `opts[:relay_state]` is required and must match the relay_state captured in `request_intent`.
  """
  @spec consume_response(binary(), map() | keyword(), keyword()) ::
          {:ok, map()} | {:error, Relyra.Error.t()}
  def consume_response(response_payload, request_intent_or_opts, opts \\ []) do
    with {:ok, request_intent, consume_opts} <-
           resolve_request_intent(request_intent_or_opts, opts),
         :ok <- validate_request_intent(request_intent),
         :ok <- validate_relay_state_opt(consume_opts, request_intent),
         {:ok, connection} <- resolve_connection_context(request_intent, consume_opts),
         result <-
           ValidationPipeline.run(response_payload, request_intent, connection, consume_opts),
         {:ok, login_result} <- normalize_consume_result(result),
         :ok <- consume_replay_key(login_result, connection, consume_opts),
         :ok <- consume_request_intent(request_intent, consume_opts) do
      {:ok, login_result}
    else
      {:error, %Error{} = error} ->
        {:error, error}
    end
  rescue
    exception ->
      {:error,
       Error.new(
         :internal_protocol_error,
         "consume_response/3 raised an unexpected exception",
         %{stage: :consume_response, reason: Exception.message(exception)}
       )}
  catch
    kind, reason ->
      {:error,
       Error.new(
         :internal_protocol_error,
         "consume_response/3 trapped a non-local exit",
         %{stage: :consume_response, kind: kind, reason: inspect(reason)}
       )}
  end

  defp normalize_consume_result({:ok, login_result}) when is_map(login_result),
    do: {:ok, Map.new(login_result)}

  defp normalize_consume_result({:error, %Error{} = error}), do: {:error, error}

  defp normalize_consume_result(_result) do
    {:error,
     Error.new(
       :internal_protocol_error,
       "Validation pipeline returned unexpected tuple shape",
       %{stage: :consume_response}
     )}
  end

  defp resolve_request_intent(request_intent, opts)
       when is_map(request_intent) and is_list(opts) do
    {:ok, hydrate_request_intent(request_intent), opts}
  end

  defp resolve_request_intent(request_intent_opts, opts)
       when is_list(request_intent_opts) and is_list(opts) do
    fetch_request_intent(Keyword.merge(request_intent_opts, opts))
  end

  defp resolve_request_intent(_request_intent_or_opts, opts) when is_list(opts) do
    fetch_request_intent(opts)
  end

  defp fetch_request_intent(opts) when is_list(opts) do
    relay_state = opts[:relay_state]

    if is_binary(relay_state) and relay_state != "" do
      case RequestStore.fetch_intent(opts[:relay_state], opts) do
        {:ok, request_intent} when is_map(request_intent) ->
          {:ok, hydrate_request_intent(request_intent), opts}

        {:error, %Error{type: :request_intent_not_found}} ->
          {:error,
           Error.new(
             :request_intent_missing,
             "Request intent was not found for relay_state",
             %{relay_state: relay_state}
           )}

        {:error, %Error{} = error} ->
          {:error, error}

        other ->
          {:error,
           Error.new(
             :request_intent_missing,
             "Request store returned an invalid request intent result",
             %{relay_state: relay_state, actual: inspect(other)}
           )}
      end
    else
      {:error,
       Error.new(
         :request_intent_missing,
         "Request intent is required for consume_response/3",
         %{relay_state: relay_state}
       )}
    end
  end

  defp hydrate_request_intent(request_intent) when is_map(request_intent) do
    request_id =
      read_field(request_intent, :request_id) || read_field(request_intent, :in_response_to)

    request_intent
    |> Map.put_new(:request_id, request_id)
    |> Map.put_new(:in_response_to, request_id)
  end

  defp validate_request_intent(request_intent) when is_map(request_intent) do
    required_keys = [:request_id, :relay_state, :in_response_to]

    missing =
      Enum.reject(required_keys, fn key ->
        value = read_field(request_intent, key)
        is_binary(value) and value != ""
      end)

    if missing == [] do
      :ok
    else
      {:error,
       Error.new(
         :connection_binding_mismatch,
         "Request intent is missing required fields",
         %{expected: required_keys, actual: missing}
       )}
    end
  end

  defp validate_request_intent(_request_intent) do
    {:error,
     Error.new(
       :connection_binding_mismatch,
       "Request intent must be a map with required fields",
       %{expected: :map, actual: :invalid_request_intent}
     )}
  end

  defp validate_relay_state_opt(opts, request_intent)
       when is_list(opts) and is_map(request_intent) do
    posted_relay_state = Keyword.get(opts, :relay_state)
    expected_relay_state = read_field(request_intent, :relay_state)

    if is_binary(posted_relay_state) and posted_relay_state != "" do
      :ok
    else
      {:error,
       Error.new(
         :relay_state_missing,
         "opts[:relay_state] is required for consume_response/3",
         %{expected: expected_relay_state, actual: posted_relay_state}
       )}
    end
  end

  defp validate_relay_state_opt(_opts, _request_intent) do
    {:error,
     Error.new(
       :relay_state_missing,
       "opts[:relay_state] is required for consume_response/3",
       %{expected: :binary, actual: :missing}
     )}
  end

  defp resolve_connection_context(request_intent, opts)
       when is_map(request_intent) and is_list(opts) do
    case Keyword.get(opts, :connection) do
      connection when is_map(connection) and map_size(connection) > 0 ->
        {:ok, normalize_connection(connection, request_intent)}

      _ ->
        request_context = %{
          connection_id: read_field(request_intent, :connection_id),
          relay_state: read_field(request_intent, :relay_state),
          request_id: read_field(request_intent, :request_id),
          issuer: read_field(request_intent, :issuer),
          sp_entity_id: read_field(request_intent, :sp_entity_id),
          acs_url: read_field(request_intent, :acs_url)
        }

        case ConnectionResolver.resolve_connection(request_context, opts) do
          {:ok, connection} when is_map(connection) ->
            {:ok, normalize_connection(connection, request_intent)}

          {:error, %Error{} = error} ->
            {:error, error}

          other ->
            {:error,
             Error.new(
               :connection_binding_mismatch,
               "Connection resolver returned an invalid result",
               %{actual: inspect(other)}
             )}
        end
    end
  end

  defp normalize_connection(connection, request_intent)
       when is_map(connection) and is_map(request_intent) do
    connection
    |> Map.put_new(:connection_id, read_field(request_intent, :connection_id))
    |> Map.put_new(:issuer, read_field(request_intent, :issuer))
    |> Map.put_new(:idp_entity_id, read_field(request_intent, :issuer))
    |> Map.put_new(:sp_entity_id, read_field(request_intent, :sp_entity_id))
    |> Map.put_new(:acs_url, read_field(request_intent, :acs_url))
    |> Map.put_new(:cert_chain, read_field(connection, :cert_chain) || [])
  end

  defp consume_replay_key(login_result, connection, opts)
       when is_map(login_result) and is_map(connection) and is_list(opts) do
    replay_key = replay_key(login_result, connection)

    metadata = %{
      connection_id:
        read_field(connection, :connection_id) || read_field(login_result, :connection_id),
      issuer: read_field(login_result, :issuer) || read_field(connection, :issuer),
      signed_xml_id: read_field(login_result, :signed_xml_id),
      relay_state: opts[:relay_state]
    }

    case ReplayStore.consume_replay_key(replay_key, metadata, opts) do
      :ok ->
        :ok

      {:error, %Error{type: :replayed_assertion} = error} ->
        {:error, error}

      {:error, %Error{} = error} ->
        {:error,
         Error.new(
           :replayed_assertion,
           "Replay consume gate failed",
           %{replay_key: replay_key, reason: error.type, details: error.details}
         )}

      other ->
        {:error,
         Error.new(
           :replayed_assertion,
           "Replay consume gate returned unexpected result",
           %{replay_key: replay_key, actual: inspect(other)}
         )}
    end
  end

  defp consume_request_intent(request_intent, opts)
       when is_map(request_intent) and is_list(opts) do
    relay_state = read_field(request_intent, :relay_state) || opts[:relay_state]
    request_id = read_field(request_intent, :request_id)

    case RequestStore.consume_intent(relay_state, request_id, opts) do
      :ok ->
        :ok

      {:error, %Error{type: :request_intent_consumed} = error} ->
        {:error, error}

      {:error, %Error{} = error} ->
        {:error,
         Error.new(
           :request_intent_consumed,
           "Request intent consume gate failed",
           %{
             relay_state: relay_state,
             request_id: request_id,
             reason: error.type,
             details: error.details
           }
         )}

      other ->
        {:error,
         Error.new(
           :request_intent_consumed,
           "Request intent consume gate returned unexpected result",
           %{relay_state: relay_state, request_id: request_id, actual: inspect(other)}
         )}
    end
  end

  defp persist_request_intent(relay_state, intent, opts)
       when is_binary(relay_state) and is_map(intent) and is_list(opts) do
    case RequestStore.put_intent(relay_state, intent, opts) do
      :ok ->
        :ok

      {:error, %Error{} = error} ->
        {:error,
         Error.new(
           :request_store_failure,
           "Failed to persist request intent",
           %{relay_state: relay_state, reason: error.type, details: error.details}
         )}

      other ->
        {:error,
         Error.new(
           :request_store_failure,
           "Request store returned unexpected put_intent result",
           %{relay_state: relay_state, actual: inspect(other)}
         )}
    end
  end

  defp build_request_intent(request_id, relay_state, connection, issued_at, expires_at)
       when is_binary(request_id) and is_binary(relay_state) and is_map(connection) do
    %{
      request_id: request_id,
      relay_state: relay_state,
      connection_id: read_field(connection, :connection_id),
      issuer: read_field(connection, :issuer) || read_field(connection, :idp_entity_id),
      sp_entity_id: read_field(connection, :sp_entity_id),
      acs_url: read_field(connection, :acs_url),
      issued_at: issued_at,
      expires_at: expires_at
    }
  end

  defp intent_issued_at(opts) when is_list(opts) do
    case Keyword.get(opts, :now) do
      %DateTime{} = value -> value
      _ -> DateTime.utc_now()
    end
  end

  defp intent_expires_at(%DateTime{} = issued_at, opts) when is_list(opts) do
    ttl_seconds =
      case Keyword.get(opts, :request_intent_ttl_seconds, @default_request_intent_ttl_seconds) do
        ttl when is_integer(ttl) and ttl > 0 -> ttl
        _ -> @default_request_intent_ttl_seconds
      end

    DateTime.add(issued_at, ttl_seconds, :second)
  end

  defp replay_key(login_result, connection) do
    connection_id =
      read_field(connection, :connection_id) || read_field(login_result, :connection_id)

    issuer = read_field(login_result, :issuer) || read_field(connection, :issuer)
    signed_xml_id = read_field(login_result, :signed_xml_id)

    "#{connection_id}:#{issuer}:#{signed_xml_id}"
  end

  defp read_field(map, key) when is_map(map) and is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
