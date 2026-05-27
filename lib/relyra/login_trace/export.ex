defmodule Relyra.LoginTrace.Export do
  @moduledoc """
  Shared redaction and export for login trace steps and audit rows.

  LiveView and CLI both call this module so TRACE-03 redaction-equivalence is
  provable in tests.
  """

  alias Relyra.Diagnostic.AllowList
  alias Relyra.Ecto.AuditEvent

  @redacted "[REDACTED]"

  @sensitive_keys MapSet.new([
                    "assertion_xml",
                    "certificate_pem",
                    "certificate_pems",
                    "metadata_xml",
                    "pem",
                    "private_key",
                    "private_key_pem",
                    "relay_state",
                    "response_xml",
                    "sensitive",
                    "signature",
                    "signature_value",
                    "signed_xml",
                    "xml"
                  ])

  @forbidden_patterns ~r/-----BEGIN|<\s*saml/i

  @allowed_step_keys MapSet.new([
                       "outcome",
                       "error_code",
                       "duration_ms",
                       "attributes",
                       "roles",
                       "step"
                     ])

  @step_order [
    "response.decode",
    "response.validate",
    "signature.verify",
    "replay.check",
    "user.map",
    "session.establish"
  ]

  @doc """
  Exports a single consume-path step map with sensitive values scrubbed.

  Returns string-keyed maps containing only `outcome`, `error_code`, `duration_ms`,
  and redacted attribute summaries.
  """
  @spec export_step(map()) :: map()
  def export_step(step) when is_map(step) do
    step
    |> scrub_value()
    |> Enum.filter(fn {key, _value} ->
      key = normalize_key(key)
      MapSet.member?(@allowed_step_keys, key)
    end)
    |> Map.new(fn {key, value} -> {normalize_key(key), value} end)
    |> reject_nil()
  end

  @doc """
  Exports a login-domain audit row for UI/CLI display.

  Drops `actor`, hashes `correlation_id`, and maps nested steps through
  `export_step/1`.
  """
  @spec export_login(AuditEvent.t() | map()) :: map()
  def export_login(%AuditEvent{} = event), do: export_login(Map.from_struct(event))

  def export_login(event) when is_map(event) do
    after_summary = Map.get(event, :after_summary) || Map.get(event, "after_summary") || %{}
    steps_map = Map.get(after_summary, "steps") || Map.get(after_summary, :steps) || %{}

    steps =
      Enum.flat_map(@step_order, fn step_name ->
        case fetch_step(steps_map, step_name) do
          nil -> []
          step -> [export_step(Map.put(normalize_map_keys(step), "step", step_name))]
        end
      end)

    %{
      id: Map.get(event, :id) || Map.get(event, "id"),
      action: Map.get(event, :action) || Map.get(event, "action"),
      cause: Map.get(event, :cause) || Map.get(event, "cause"),
      inserted_at: Map.get(event, :inserted_at) || Map.get(event, "inserted_at"),
      correlation_id:
        AllowList.hash_correlation_id(
          Map.get(event, :correlation_id) || Map.get(event, "correlation_id")
        ),
      steps: steps
    }
    |> reject_nil()
  end

  defp scrub_value(value) when is_map(value) do
    value
    |> normalize_map_keys()
    |> Map.new(fn {key, nested} ->
      cond do
        sensitive_key?(key) -> {key, @redacted}
        true -> {key, scrub_value(nested)}
      end
    end)
  end

  defp scrub_value(value) when is_list(value) do
    Enum.map(value, &scrub_value/1)
  end

  defp scrub_value(value) when is_binary(value) do
    cond do
      Regex.match?(@forbidden_patterns, value) -> @redacted
      sensitive_binary?(value) -> @redacted
      true -> value
    end
  end

  defp scrub_value(value), do: value

  defp sensitive_key?(key) do
    key
    |> normalize_key()
    |> String.downcase()
    |> then(&MapSet.member?(@sensitive_keys, &1))
  end

  defp sensitive_binary?(value) do
    String.contains?(value, "BEGIN CERTIFICATE") or
      String.contains?(value, "BEGIN PRIVATE KEY") or
      String.contains?(value, "BEGIN RSA PRIVATE KEY")
  end

  defp normalize_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_key(key) when is_binary(key), do: key
  defp normalize_key(key), do: to_string(key)

  defp normalize_map_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {normalize_key(key), value} end)
  end

  defp fetch_step(steps_map, step_name) when is_map(steps_map) do
    Map.get(steps_map, step_name) ||
      case Map.fetch(steps_map, String.to_existing_atom(step_name)) do
        {:ok, step} -> step
        :error -> nil
      end
  rescue
    ArgumentError -> nil
  end

  defp reject_nil(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
