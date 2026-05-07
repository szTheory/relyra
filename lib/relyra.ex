defmodule Relyra do
  @moduledoc """
  Public entry points for strict-by-default SAML protocol flows.
  """

  alias Relyra.ConnectionResolver
  alias Relyra.Error
  alias Relyra.Protocol.AuthnRequest
  alias Relyra.Protocol.Binding
  alias Relyra.Protocol.ValidationPipeline
  alias Relyra.RequestStore
  alias Relyra.Security.RelayState

  @default_request_intent_ttl_seconds 300

  @spec start_login(map(), map(), keyword()) :: {:ok, map()} | {:error, Relyra.Error.t()}
  def start_login(connection, relay_context, opts \\ []) do
    metadata = %{
      connection_id: read_field(connection, :connection_id),
      organization_id: read_field(connection, :organization_id),
      provider_preset: read_field(connection, :provider_preset),
      flow: :sp_initiated,
      binding: :redirect
    }

    Relyra.Telemetry.span([:login], metadata, fn ->
      result = do_start_login(connection, relay_context, opts)

      case result do
        {:ok, _} = ok ->
          {ok, Map.put(metadata, :outcome, :ok)}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  defp do_start_login(connection, relay_context, opts) do
    metadata = %{
      connection_id: read_field(connection, :connection_id),
      organization_id: read_field(connection, :organization_id),
      provider_preset: read_field(connection, :provider_preset),
      flow: :sp_initiated,
      binding: :redirect
    }

    Relyra.Telemetry.span([:authn_request], metadata, fn ->
      with {:ok, request_fields} <- AuthnRequest.build(connection, relay_context, opts),
           request_id <- Map.fetch!(request_fields, :id),
           authn_request_xml <- AuthnRequest.to_xml(request_fields),
           {:ok, relay_state} <-
             RelayState.issue(Map.put(relay_context, :request_id, request_id), opts),
           issued_at <- intent_issued_at(opts),
           expires_at <- intent_expires_at(issued_at, opts),
           intent <-
             build_request_intent(request_id, relay_state, connection, issued_at, expires_at) do
        request_store_start = System.monotonic_time()
        request_store_result = persist_request_intent(relay_state, intent, opts)
        request_store_latency_ms = duration_ms(request_store_start)

        case request_store_result do
          :ok ->
            case Binding.encode_redirect(authn_request_xml, relay_state) do
              {:ok, redirect_params} ->
                base64_request = Map.get(redirect_params, "SAMLRequest") || ""

                {
                  {:ok,
                   %{
                     request_id: request_id,
                     authn_request: authn_request_xml,
                     relay_state: relay_state,
                     redirect_params: redirect_params
                   }},
                  Map.merge(metadata, %{
                    outcome: :ok,
                    xml_bytes: byte_size(authn_request_xml),
                    base64_bytes: byte_size(base64_request),
                    request_store_latency_ms: request_store_latency_ms
                  })
                }

              {:error, %Error{} = error} ->
                {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
            end

          {:error, %Error{} = error} ->
            {{:error, error},
             Map.merge(metadata, %{
               outcome: :error,
               error_code: error.type,
               request_store_latency_ms: request_store_latency_ms
             })}
        end
      else
        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  @spec consume_response(binary(), map() | keyword(), keyword()) ::
          {:ok, map()} | {:error, Relyra.Error.t()}
  def consume_response(response_payload, request_intent_or_opts, opts \\ []) do
    metadata = %{
      flow: :sp_initiated
    }

    Relyra.Telemetry.span([:response, :consume], metadata, fn ->
      try do
        result = do_consume_response(response_payload, request_intent_or_opts, opts)

        case result do
          {:ok, login_result} ->
            final_metadata =
              Map.merge(metadata, %{
                outcome: :ok,
                connection_id: read_field(login_result, :connection_id)
              })

            {{:ok, login_result}, final_metadata}

          {:error, %Error{} = error} ->
            {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
        end
      rescue
        exception ->
          error =
            Error.new(
              :internal_protocol_error,
              "consume_response/3 raised an unexpected exception",
              %{stage: :consume_response, reason: Exception.message(exception)}
            )

          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      catch
        kind, reason ->
          error =
            Error.new(
              :internal_protocol_error,
              "consume_response/3 trapped a non-local exit",
              %{stage: :consume_response, kind: kind, reason: inspect(reason)}
            )

          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  defp do_consume_response(response_payload, request_intent_or_opts, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    with {:ok, request_intent, consume_opts} <-
           resolve_request_intent(request_intent_or_opts, opts),
         :ok <- validate_relay_state_opt(consume_opts, request_intent),
         :ok <- validate_request_intent(request_intent, consume_opts),
         :ok <- validate_request_intent_expiry(request_intent, now),
         {:ok, connection} <- resolve_connection_context(request_intent, consume_opts),
         {:ok, result_map} <-
           ValidationPipeline.run(response_payload, request_intent, connection, consume_opts),
         :ok <- consume_replay_key(result_map, connection, consume_opts),
         :ok <- consume_request_intent(request_intent, consume_opts),
         {:ok, login_result} <- normalize_consume_result(result_map) do
      {:ok, login_result}
    else
      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp validate_request_intent_expiry(%{expires_at: expires_at}, now) do
    expires_at = maybe_parse_iso8601(expires_at)

    case DateTime.compare(expires_at, now) do
      :gt -> :ok
      _ -> {:error, Error.new(:request_intent_expired, "Request intent has expired")}
    end
  end

  defp validate_request_intent_expiry(_, _now), do: :ok

  defp maybe_parse_iso8601(%DateTime{} = dt), do: dt

  defp maybe_parse_iso8601(bin) when is_binary(bin) do
    case DateTime.from_iso8601(bin) do
      {:ok, dt, _} -> dt
      _ -> DateTime.from_unix!(0)
    end
  end

  defp maybe_parse_iso8601(_), do: DateTime.from_unix!(0)

  defp normalize_consume_result(result) when is_map(result) do
    principal = %Relyra.Principal{
      name_id: Map.get(result, :name_id),
      name_id_format: Map.get(result, :name_id_format),
      session_index: Map.get(result, :session_index),
      attributes: Map.get(result, :attributes),
      connection_id: Map.get(result, :connection_id)
    }

    login_result = %Relyra.LoginResult{
      principal: principal,
      connection: Map.get(result, :connection),
      relay_state: Map.get(result, :relay_state),
      issuer: Map.get(result, :issuer),
      in_response_to: Map.get(result, :in_response_to),
      return_to: Map.get(result, :return_to)
    }

    {:ok, login_result}
  end

  defp resolve_request_intent(request_intent, opts) when is_map(request_intent) do
    if Keyword.get(opts, :relay_state) do
      {:ok, request_intent, opts}
    else
      {:error, Error.new(:relay_state_missing, "RelayState is required in opts")}
    end
  end

  defp resolve_request_intent(opts, []) when is_list(opts) do
    relay_state = Keyword.get(opts, :relay_state)

    if relay_state do
      case RequestStore.fetch_intent(relay_state, opts) do
        {:ok, intent} ->
          {:ok, intent, opts}

        {:error, %Error{type: :adapter_not_configured} = error} ->
          {:error, error}

        {:error, _} ->
          # If not found in store, we might be in an IdP-initiated flow.
          # We return nil intent and let the pipeline decide based on connection config.
          {:ok, nil, opts}
      end
    else
      # No relay_state and no intent map provided.
      # We return nil intent and assume connection will be provided in opts.
      {:ok, nil, opts}
    end
  end

  defp validate_request_intent(nil, _opts), do: :ok

  defp validate_request_intent(intent, _opts) do
    required = [:request_id, :sp_entity_id, :acs_url]
    missing = Enum.filter(required, fn key -> is_nil(Map.get(intent, key)) end)

    if missing == [] do
      :ok
    else
      {:error,
       Error.new(:request_intent_invalid, "Stored request intent is missing required fields", %{
         missing: missing
       })}
    end
  end

  defp validate_relay_state_opt(opts, request_intent) do
    case Keyword.get(opts, :relay_state) do
      nil ->
        :ok

      actual ->
        expected = Map.get(request_intent || %{}, :relay_state)

        if is_nil(expected) or actual == expected do
          :ok
        else
          {:error,
           Error.new(
             :relay_state_mismatch,
             "Provided relay_state does not match stored intent",
             %{
               expected: expected,
               actual: actual
             }
           )}
        end
    end
  end

  defp resolve_connection_context(request_intent, opts) do
    case Keyword.get(opts, :connection) || Keyword.get(opts, :resolved_connection) do
      connection when is_map(connection) ->
        {:ok, connection}

      _ ->
        request_context = %{
          connection_id: read_field(request_intent, :connection_id),
          organization_id: read_field(request_intent, :organization_id)
        }

        ConnectionResolver.resolve_connection(request_context, opts)
    end
  end

  defp consume_replay_key(login_result, _connection, opts) do
    issuer = Map.get(login_result, :issuer)
    signed_xml_id = Map.get(login_result, :signed_xml_id)
    connection_id = Map.get(login_result, :connection_id)

    replay_key = build_replay_key(connection_id, issuer, signed_xml_id)

    metadata = %{
      connection_id: connection_id,
      issuer: issuer,
      assertion_id: signed_xml_id
    }

    Relyra.ReplayStore.consume_replay_key(replay_key, metadata, opts)
  end

  defp consume_request_intent(nil, _opts), do: :ok

  defp consume_request_intent(request_intent, opts) do
    relay_state = Map.get(request_intent, :relay_state)
    request_id = Map.get(request_intent, :request_id)

    RequestStore.consume_intent(relay_state, request_id, opts)
  end

  defp persist_request_intent(relay_state, intent, opts) do
    RequestStore.put_intent(relay_state, intent, opts)
  end

  defp intent_issued_at(opts) do
    Keyword.get(opts, :now, DateTime.utc_now())
  end

  defp intent_expires_at(issued_at, opts) do
    ttl = Keyword.get(opts, :ttl_seconds, @default_request_intent_ttl_seconds)
    DateTime.add(issued_at, ttl, :second)
  end

  defp build_request_intent(request_id, relay_state, connection, issued_at, expires_at) do
    %{
      request_id: request_id,
      relay_state: relay_state,
      connection_id: read_field(connection, :connection_id) || read_field(connection, :id),
      organization_id: read_field(connection, :organization_id),
      sp_entity_id: read_field(connection, :sp_entity_id) || read_field(connection, :issuer),
      acs_url: read_field(connection, :acs_url),
      issued_at: issued_at,
      expires_at: expires_at
    }
  end

  defp build_replay_key(connection_id, issuer, signed_xml_id) do
    # Stable deterministic key for replay detection
    "#{connection_id}:#{issuer}:#{signed_xml_id}"
  end

  defp duration_ms(start_time) do
    System.convert_time_unit(System.monotonic_time() - start_time, :native, :millisecond)
  end

  defp read_field(map, key) when is_map(map) and is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
