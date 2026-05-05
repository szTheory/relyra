defmodule Relyra.Ecto.AuditWriter do
  @moduledoc false

  alias Relyra.Ecto.AuditEvent
  alias Relyra.Error

  @ecto_repo Ecto.Repo
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
                    "signed_xml",
                    "xml"
                  ])
  @max_map_entries 32
  @max_list_entries 32
  @max_binary_bytes 512
  @redacted "[REDACTED]"
  @truncated "[TRUNCATED]"

  @required_attrs [:connection_record_id, :domain, :action, :actor, :cause]

  @spec append_event(module(), map()) :: {:ok, AuditEvent.t()} | {:error, Error.t()}
  def append_event(repo, attrs) when is_atom(repo) and is_map(attrs) do
    with :ok <- ensure_optional_dependencies(repo),
         {:ok, normalized_attrs} <- normalize_attrs(attrs) do
      case %AuditEvent{} |> AuditEvent.changeset(normalized_attrs) |> repo.insert() do
        {:ok, event} ->
          {:ok, event}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:error,
           Error.new(
             :invalid_connection_record,
             "Audit event failed validation",
             %{errors: format_changeset_errors(changeset), operation: :append_event}
           )}
      end
    end
  end

  def append_event(repo, attrs) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "repo and attrs are required for audit event writes",
       %{
         repo: inspect(repo),
         operation: :append_event,
         reason: :invalid_input,
         attrs: inspect(attrs)
       }
     )}
  end

  defp ensure_optional_dependencies(repo) do
    cond do
      not Code.ensure_loaded?(@ecto_repo) ->
        optional_dependency_error(repo, :ecto_unavailable)

      not Code.ensure_loaded?(AuditEvent) ->
        optional_dependency_error(repo, :audit_event_unavailable)

      true ->
        :ok
    end
  end

  defp optional_dependency_error(repo, reason) do
    {:error,
     Error.new(
       :optional_dependency_missing,
       "Ecto audit persistence is unavailable",
       %{repo: inspect(repo), operation: :append_event, reason: inspect(reason)}
     )}
  end

  defp normalize_attrs(attrs) do
    with :ok <- validate_required_attrs(attrs) do
      before_summary =
        normalize_summary(Map.get(attrs, :before_view, Map.get(attrs, :before_summary, %{})))

      after_summary =
        normalize_summary(Map.get(attrs, :after_view, Map.get(attrs, :after_summary, %{})))

      diff_summary =
        attrs
        |> Map.get(:diff_summary, %{})
        |> normalize_summary()
        |> merge_optional_context(attrs)

      {:ok,
       %{
         connection_record_id: Map.get(attrs, :connection_record_id),
         domain: Map.get(attrs, :domain),
         action: Map.get(attrs, :action),
         actor: normalize_required_string(attrs, :actor),
         cause: normalize_required_string(attrs, :cause),
         correlation_id: normalize_optional_string(Map.get(attrs, :correlation_id)),
         before_summary: before_summary,
         after_summary: after_summary,
         diff_summary: diff_summary
       }}
    end
  end

  defp validate_required_attrs(attrs) do
    missing =
      Enum.filter(@required_attrs, fn key ->
        value = Map.get(attrs, key)
        is_nil(value) or value == ""
      end)

    if missing == [] do
      :ok
    else
      {:error,
       Error.new(
         :invalid_connection_record,
         "Audit event attrs are missing required fields",
         %{operation: :append_event, missing: missing}
       )}
    end
  end

  defp merge_optional_context(diff_summary, attrs) do
    context =
      %{}
      |> maybe_put_context(:subject_ref, Map.get(attrs, :subject_ref))
      |> maybe_put_context(:metadata, Map.get(attrs, :metadata))

    if context == %{} do
      diff_summary
    else
      normalized_context = normalize_summary(context)

      if Map.has_key?(diff_summary, :context) or Map.has_key?(diff_summary, "context") do
        diff_summary
      else
        Map.put(diff_summary, :context, normalized_context)
      end
    end
  end

  defp maybe_put_context(context, _key, nil), do: context
  defp maybe_put_context(context, _key, ""), do: context

  defp maybe_put_context(context, key, value) do
    Map.put(context, key, value)
  end

  defp normalize_required_string(attrs, key) do
    attrs
    |> Map.get(key)
    |> normalize_optional_string()
  end

  defp normalize_optional_string(nil), do: nil

  defp normalize_optional_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> limit_binary()
  end

  defp normalize_optional_string(value), do: value |> to_string() |> normalize_optional_string()

  defp normalize_summary(value) when is_map(value) do
    value
    |> Enum.take(@max_map_entries)
    |> Enum.map(fn {key, nested_value} ->
      {normalize_key(key), normalize_value(key, nested_value)}
    end)
    |> maybe_mark_truncated_map(value)
    |> Enum.into(%{})
  end

  defp normalize_summary(_value), do: %{}

  defp maybe_mark_truncated_map(entries, original) do
    if map_size(original) > @max_map_entries do
      truncated_entries = Enum.take(entries, @max_map_entries - 1)
      [{:truncated, true} | truncated_entries]
    else
      entries
    end
  end

  defp normalize_value(key, value) when is_map(value), do: normalize_nested_map(key, value)
  defp normalize_value(key, value) when is_list(value), do: normalize_list(key, value)

  defp normalize_value(key, value) when is_binary(value) do
    if sensitive_key?(key) or sensitive_binary?(value) do
      @redacted
    else
      limit_binary(value)
    end
  end

  defp normalize_value(key, value) when is_atom(value) do
    if sensitive_key?(key), do: @redacted, else: value
  end

  defp normalize_value(key, value) when is_number(value) or is_boolean(value) or is_nil(value) do
    if sensitive_key?(key), do: @redacted, else: value
  end

  defp normalize_value(key, value), do: normalize_value(key, inspect(value))

  defp normalize_nested_map(key, value) do
    if sensitive_key?(key) do
      @redacted
    else
      normalize_summary(value)
    end
  end

  defp normalize_list(key, value) do
    if sensitive_key?(key) do
      @redacted
    else
      value
      |> Enum.take(@max_list_entries)
      |> Enum.map(&normalize_list_value/1)
      |> maybe_mark_truncated_list(value)
    end
  end

  defp normalize_list_value(value) when is_map(value), do: normalize_summary(value)
  defp normalize_list_value(value) when is_list(value), do: normalize_list(:list, value)

  defp normalize_list_value(value) when is_binary(value),
    do: if(sensitive_binary?(value), do: @redacted, else: limit_binary(value))

  defp normalize_list_value(value)
       when is_atom(value) or is_number(value) or is_boolean(value) or is_nil(value), do: value

  defp normalize_list_value(value), do: limit_binary(inspect(value))

  defp maybe_mark_truncated_list(entries, original) do
    if length(original) > @max_list_entries do
      List.replace_at(entries, @max_list_entries - 1, @truncated)
    else
      entries
    end
  end

  defp normalize_key(key) when is_atom(key), do: key
  defp normalize_key(key) when is_binary(key), do: key
  defp normalize_key(key), do: to_string(key)

  defp sensitive_key?(key) do
    key
    |> normalize_key()
    |> to_string()
    |> String.downcase()
    |> then(&MapSet.member?(@sensitive_keys, &1))
  end

  defp sensitive_binary?(value) do
    String.contains?(value, "BEGIN CERTIFICATE") or
      String.contains?(value, "BEGIN PRIVATE KEY") or
      String.contains?(value, "BEGIN RSA PRIVATE KEY")
  end

  defp limit_binary(value) when is_binary(value) and byte_size(value) > @max_binary_bytes,
    do: @redacted

  defp limit_binary(value), do: value

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
