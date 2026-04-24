defmodule Relyra do
  @moduledoc """
  Public entry points for strict-by-default SAML protocol flows.
  """

  alias Relyra.Error
  alias Relyra.Protocol.AuthnRequest
  alias Relyra.Protocol.Binding
  alias Relyra.Protocol.ValidationPipeline
  alias Relyra.Security.RelayState

  # Verification anchor: def start_login(connection, relay_context, opts \ [])
  @spec start_login(map(), map(), keyword()) :: {:ok, map()} | {:error, Relyra.Error.t()}
  def start_login(connection, relay_context, opts \\ []) do
    with {:ok, request_fields} <- AuthnRequest.build(connection, relay_context, opts),
         request_id <- Map.fetch!(request_fields, :id),
         authn_request_xml <- AuthnRequest.to_xml(request_fields),
         {:ok, relay_state} <-
           RelayState.issue(Map.put(relay_context, :request_id, request_id), opts),
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

  @spec consume_response(binary(), map(), keyword()) :: {:ok, map()} | {:error, Relyra.Error.t()}
  def consume_response(response_payload, request_intent, opts \\ []) do
    with :ok <- validate_request_intent(request_intent),
         connection <- connection_context(request_intent, opts),
         result <- ValidationPipeline.run(response_payload, request_intent, connection, opts) do
      normalize_consume_result(result)
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
    do: {:ok, login_result}

  defp normalize_consume_result({:error, %Error{} = error}), do: {:error, error}

  defp normalize_consume_result(_result) do
    {:error,
     Error.new(
       :internal_protocol_error,
       "Validation pipeline returned unexpected tuple shape",
       %{stage: :consume_response}
     )}
  end

  defp validate_request_intent(request_intent) when is_map(request_intent) do
    required_keys = [:request_id, :connection_id, :relay_state, :in_response_to]

    missing =
      Enum.reject(required_keys, fn key ->
        value = Map.get(request_intent, key) || Map.get(request_intent, Atom.to_string(key))
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

  defp connection_context(request_intent, opts) do
    connection =
      case Keyword.get(opts, :connection, %{}) do
        map when is_map(map) -> map
        _ -> %{}
      end

    Map.put_new(connection, :connection_id, Map.get(request_intent, :connection_id))
  end
end
