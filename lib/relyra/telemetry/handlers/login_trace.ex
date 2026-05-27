defmodule Relyra.Telemetry.Handlers.LoginTrace do
  @moduledoc """
  Telemetry handler that accumulates consume-path span outcomes and flushes one
  `domain: :login` audit row per `consume_response/3` attempt.

  Hosts with Ecto should call `attach(repo: MyApp.Repo)` from `Application.start/2`
  so login traces persist without manual telemetry wiring.

  Login trace writes use `AuditWriter.append_event/2` outside trust-mutation
  transactions. Sensitive keys are stripped before persistence.
  """

  require Logger

  alias Relyra.Ecto.{AuditWriter, Connection}

  @handler_id :relyra_login_trace
  @trace_key :relyra_login_trace
  @validation_trace_key :relyra_validation_trace

  @step_order [
    "response.decode",
    "response.validate",
    "signature.verify",
    "replay.check",
    "user.map",
    "session.establish"
  ]

  @child_stops [
    [:relyra, :saml, :response, :decode, :stop],
    [:relyra, :saml, :response, :validate, :stop],
    [:relyra, :saml, :signature, :verify, :stop],
    [:relyra, :saml, :replay, :check, :stop],
    [:relyra, :saml, :user, :map, :stop],
    [:relyra, :saml, :session, :establish, :stop]
  ]

  @consume_events [
    [:relyra, :saml, :response, :consume, :start],
    [:relyra, :saml, :response, :consume, :stop],
    [:relyra, :saml, :response, :consume, :exception]
  ]

  @events @consume_events ++ @child_stops

  @sensitive_keys [
    :xml,
    :metadata_xml,
    :certificate_pem,
    :pem,
    :private_key,
    :private_key_pem,
    :response_xml,
    :assertion_xml,
    :signed_xml,
    :signature_value,
    :signature
  ]

  @spec attach(keyword()) :: :ok | {:error, :already_exists}
  def attach(opts) when is_list(opts) do
    repo = Keyword.fetch!(opts, :repo)
    :telemetry.attach_many(@handler_id, @events, &__MODULE__.handle_event/4, %{repo: repo})
  end

  @spec detach() :: :ok | {:error, :not_found}
  def detach, do: :telemetry.detach(@handler_id)

  @doc false
  def handle_event(event, measurements, metadata, config) do
    try do
      do_handle_event(event, measurements, metadata, config)
    rescue
      exception ->
        Logger.error(
          "LoginTrace handler crashed: #{Exception.message(exception)} — clearing process state"
        )

        Process.delete(@trace_key)
        Process.delete(@validation_trace_key)
    end
  end

  defp do_handle_event(
         [:relyra, :saml, :response, :consume, :start],
         _measurements,
         metadata,
         %{repo: repo}
       ) do
    correlation_id =
      metadata
      |> Map.get(:correlation_id)
      |> normalize_optional_string()
      |> case do
        nil -> Ecto.UUID.generate()
        value -> value
      end

    flow =
      metadata
      |> Map.get(:flow, :sp_initiated)
      |> normalize_flow()

    Process.put(@trace_key, %{
      repo: repo,
      steps: %{},
      connection_id: normalize_optional_string(Map.get(metadata, :connection_id)),
      correlation_id: correlation_id,
      flow: flow
    })

    :ok
  end

  defp do_handle_event(
         [:relyra, :saml, :response, :consume, stage],
         _measurements,
         metadata,
         _config
       )
       when stage in [:stop, :exception] do
    case Process.get(@trace_key) do
      %{repo: repo} = state ->
        state =
          state
          |> merge_connection_id(metadata)
          |> merge_flow(metadata)

        overall_outcome = overall_outcome(metadata, stage)
        steps = Map.get(state, :steps, %{})
        validation_trace = steps_to_list(steps)

        Process.put(@validation_trace_key, validation_trace)

        attrs = %{
          domain: :login,
          action: if(overall_outcome == "ok", do: :succeeded, else: :failed),
          actor: "system:login_trace",
          cause: state.flow,
          correlation_id: state.correlation_id,
          before_summary: %{},
          after_summary: %{
            "steps" => steps,
            "overall_outcome" => overall_outcome
          },
          diff_summary: %{"kind" => "login_trace"}
        }

        maybe_append_event(repo, state.connection_id, attrs)
        Process.delete(@trace_key)

      _ ->
        :ok
    end
  end

  defp do_handle_event(event, measurements, metadata, _config) do
    case Process.get(@trace_key) do
      %{steps: steps} = state ->
        step_name = step_name_from_event(event)

        step_summary =
          measurements
          |> Map.merge(metadata)
          |> redact()
          |> summarize_step()

        steps = Map.put(steps, step_name, step_summary)
        state = %{state | steps: steps} |> merge_connection_id(metadata)
        Process.put(@trace_key, state)
        Process.put(@validation_trace_key, steps_to_list(steps))

      _ ->
        :ok
    end
  end

  defp maybe_append_event(repo, connection_id, attrs) when is_binary(connection_id) do
    case repo.get_by(Connection, connection_id: connection_id) do
      %Connection{id: connection_record_id} ->
        attrs = Map.put(attrs, :connection_record_id, connection_record_id)
        _ = AuditWriter.append_event(repo, attrs)
        :ok

      nil ->
        :ok
    end
  end

  defp maybe_append_event(_repo, _connection_id, _attrs), do: :ok

  defp summarize_step(metadata) do
    %{
      "outcome" => outcome_string(Map.get(metadata, :outcome)),
      "error_code" => error_code_string(Map.get(metadata, :error_code)),
      "duration_ms" => Map.get(metadata, :duration_ms)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp steps_to_list(steps) when is_map(steps) do
    Enum.flat_map(@step_order, fn step_name ->
      case Map.get(steps, step_name) do
        nil -> []
        summary -> [Map.put(summary, "step", step_name)]
      end
    end)
  end

  defp step_name_from_event([:relyra, :saml | parts]) do
    parts
    |> Enum.drop(-1)
    |> Enum.map(&to_string/1)
    |> Enum.join(".")
  end

  defp merge_connection_id(state, metadata) do
    case normalize_optional_string(Map.get(metadata, :connection_id)) do
      nil -> state
      connection_id -> %{state | connection_id: connection_id}
    end
  end

  defp merge_flow(state, metadata) do
    case Map.get(metadata, :flow) do
      nil -> state
      flow -> %{state | flow: normalize_flow(flow)}
    end
  end

  defp overall_outcome(_metadata, :exception), do: "error"

  defp overall_outcome(metadata, :stop) do
    case Map.get(metadata, :outcome) do
      :ok -> "ok"
      _ -> "error"
    end
  end

  defp normalize_flow(flow) when is_atom(flow), do: Atom.to_string(flow)
  defp normalize_flow(flow) when is_binary(flow), do: flow
  defp normalize_flow(_flow), do: "unknown"

  defp normalize_optional_string(nil), do: nil

  defp normalize_optional_string(value) when is_binary(value) do
    trimmed = String.trim(value)
    if trimmed == "", do: nil, else: trimmed
  end

  defp normalize_optional_string(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_optional_string(value), do: value |> to_string() |> normalize_optional_string()

  defp outcome_string(:ok), do: "ok"
  defp outcome_string(:error), do: "error"
  defp outcome_string(value) when is_atom(value), do: Atom.to_string(value)
  defp outcome_string(value) when is_binary(value), do: value
  defp outcome_string(_value), do: nil

  defp error_code_string(nil), do: nil
  defp error_code_string(value) when is_atom(value), do: Atom.to_string(value)
  defp error_code_string(value) when is_binary(value), do: value
  defp error_code_string(value), do: inspect(value)

  defp redact(metadata) when is_map(metadata) do
    Map.drop(metadata, @sensitive_keys)
  end
end
