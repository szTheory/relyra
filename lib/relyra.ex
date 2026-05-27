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
      with :ok <- validate_idp_sso_url(connection),
           {:ok, request_fields} <- AuthnRequest.build(connection, relay_context, opts),
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
            sign = read_field(connection, :sign_authn_requests) == true
            encoding = read_field(connection, :signed_request_encoding) || :rfc3986_upper

            binding_opts =
              [
                sign: sign,
                signature_method:
                  Keyword.get(
                    opts,
                    :signature_method,
                    "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
                  ),
                signing_key_pem: Keyword.get(opts, :signing_key_pem),
                encoding: encoding,
                connection_id: read_field(connection, :connection_id)
              ]

            case Binding.encode_redirect(authn_request_xml, relay_state, binding_opts) do
              {:ok, %{redirect_query: redirect_query}} ->
                {
                  {:ok,
                   %{
                     request_id: request_id,
                     authn_request: authn_request_xml,
                     relay_state: relay_state,
                     redirect_query: redirect_query
                   }},
                  Map.merge(metadata, %{
                    outcome: :ok,
                    xml_bytes: byte_size(authn_request_xml),
                    redirect_query_bytes: byte_size(redirect_query),
                    request_store_latency_ms: request_store_latency_ms
                  })
                }

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

  @doc """
  Starts an SP-initiated Single Logout flow.
  """
  @spec start_logout(map(), binary(), keyword()) :: {:ok, map()} | {:error, Relyra.Error.t()}
  def start_logout(connection, session_index, opts \\ []) do
    metadata = %{
      connection_id: read_field(connection, :connection_id),
      organization_id: read_field(connection, :organization_id),
      provider_preset: read_field(connection, :provider_preset),
      flow: :sp_initiated_logout,
      binding: Keyword.get(opts, :binding, :redirect)
    }

    Relyra.Telemetry.span([:logout, :start], metadata, fn ->
      result = do_start_logout(connection, session_index, opts)

      case result do
        {:ok, _} = ok ->
          {ok, Map.put(metadata, :outcome, :ok)}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  defp do_start_logout(connection, session_index, opts) do
    opts_with_session = Keyword.put(opts, :session_index, session_index)
    relay_context = %{}

    with {:ok, request_fields} <-
           Relyra.Protocol.LogoutRequest.build(connection, relay_context, opts_with_session),
         request_id <- Map.fetch!(request_fields, :id),
         logout_request_xml <- Relyra.Protocol.LogoutRequest.to_xml(request_fields) do
      binding = Keyword.get(opts, :binding, :redirect)
      sign = read_field(connection, :sign_authn_requests) == true

      encoding = read_field(connection, :signed_request_encoding) || :rfc3986_upper

      binding_opts = [
        sign: sign,
        signature_method:
          Keyword.get(
            opts,
            :signature_method,
            "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
          ),
        signing_key_pem: Keyword.get(opts, :signing_key_pem),
        encoding: encoding,
        connection_id: read_field(connection, :connection_id),
        type: :request
      ]

      relay_state = Keyword.get(opts, :relay_state)

      case binding do
        :redirect ->
          case Binding.encode_redirect(logout_request_xml, relay_state, binding_opts) do
            {:ok, %{redirect_query: redirect_query}} ->
              {:ok,
               %{
                 request_id: request_id,
                 logout_request: logout_request_xml,
                 redirect_query: redirect_query,
                 relay_state: relay_state
               }}

            {:ok, redirect_params} ->
              {:ok,
               %{
                 request_id: request_id,
                 logout_request: logout_request_xml,
                 redirect_params: redirect_params,
                 relay_state: relay_state
               }}

            {:error, error} ->
              {:error, error}
          end

        :post ->
          b64 = Base.encode64(logout_request_xml)

          params =
            if relay_state,
              do: %{"SAMLRequest" => b64, "RelayState" => relay_state},
              else: %{"SAMLRequest" => b64}

          {:ok,
           %{
             request_id: request_id,
             logout_request: logout_request_xml,
             post_params: params,
             relay_state: relay_state
           }}
      end
    end
  end

  @doc """
  Consumes an inbound SAML LogoutRequest or LogoutResponse payload.
  """
  @spec consume_logout(map(), binary(), keyword()) :: {:ok, map()} | {:error, Relyra.Error.t()}
  def consume_logout(connection, raw_payload, opts \\ []) do
    metadata = %{
      connection_id: read_field(connection, :connection_id)
    }

    Relyra.Telemetry.span([:logout, :consume], metadata, fn ->
      try do
        result = do_consume_logout(connection, raw_payload, opts)

        case result do
          {:ok, logout_result} ->
            final_metadata =
              Map.merge(metadata, %{
                outcome: :ok,
                type: logout_result.type
              })

            {{:ok, logout_result}, final_metadata}

          {:error, %Error{} = error} ->
            {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
        end
      rescue
        exception ->
          error =
            Error.new(
              :internal_protocol_error,
              "consume_logout/3 raised an unexpected exception",
              %{reason: Exception.message(exception)}
            )

          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      catch
        kind, reason ->
          error =
            Error.new(:internal_protocol_error, "consume_logout/3 trapped a non-local exit", %{
              kind: kind,
              reason: inspect(reason)
            })

          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end

  defp do_consume_logout(connection, raw_payload, opts) do
    binding = Keyword.get(opts, :binding, :post)
    type = detect_logout_type(raw_payload, binding)

    case type do
      :request ->
        with {:ok, message} <-
               Relyra.Security.LogoutValidator.validate_logout_request(
                 raw_payload,
                 connection,
                 opts
               ),
             :ok <- handle_idp_initiated_logout(message, connection, opts) do
          {:ok, %{type: :request, message: message}}
        end

      :response ->
        with {:ok, message} <-
               Relyra.Security.LogoutValidator.validate_logout_response(
                 raw_payload,
                 connection,
                 opts
               ) do
          {:ok, %{type: :response, message: message}}
        end

      :unknown ->
        {:error,
         Error.new(
           :invalid_logout_payload,
           "Could not detect SAMLRequest or SAMLResponse in payload",
           %{}
         )}
    end
  end

  defp detect_logout_type(payload, :redirect) do
    parts = URI.decode_query(payload)

    cond do
      Map.has_key?(parts, "SAMLRequest") -> :request
      Map.has_key?(parts, "SAMLResponse") -> :response
      true -> :unknown
    end
  end

  defp detect_logout_type(payload, :post) do
    cond do
      String.contains?(payload, "LogoutRequest") -> :request
      String.contains?(payload, "LogoutResponse") -> :response
      true -> :unknown
    end
  end

  defp handle_idp_initiated_logout(message, connection, opts) do
    session_index = Map.get(message, :session_index)
    issuer = Map.get(message, :issuer)

    if session_index do
      context = %{
        connection_id: read_field(connection, :connection_id) || read_field(connection, :id)
      }

      # We attempt to terminate the session using the configured adapter.
      # If the adapter is not configured, we ignore the error as per adapter contract,
      # but we MUST NOT fail the SAML protocol verification itself.
      case Relyra.SessionAdapter.terminate_by_session_index(session_index, issuer, context, opts) do
        {:ok, _} -> :ok
        {:error, %Error{type: :adapter_not_configured}} -> :ok
        {:error, %Error{} = error} -> {:error, error}
      end
    else
      :ok
    end
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

  defp validate_idp_sso_url(connection) do
    details = %{connection_id: read_field(connection, :connection_id)}

    case read_field(connection, :idp_sso_url) do
      url when is_binary(url) and url != "" ->
        reserved_keys = ["SAMLRequest", "SAMLResponse", "RelayState", "SigAlg", "Signature"]
        query = URI.parse(url).query || ""

        case Enum.find(reserved_keys, &Map.has_key?(URI.decode_query(query), &1)) do
          nil ->
            :ok

          reserved_key ->
            {:error,
             Error.new(
               :invalid_idp_sso_url,
               "idp_sso_url query string already contains a reserved SAML parameter",
               Map.merge(details, %{
                 reserved_key: reserved_key,
                 hint:
                   "Configure idp_sso_url without SAML query parameters; SAML parameters are appended at sign time"
               })
             )}
        end

      _ ->
        :ok
    end
  end

  defp read_field(map, key) when is_map(map) and is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
