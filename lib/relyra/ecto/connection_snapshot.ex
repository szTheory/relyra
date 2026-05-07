defmodule Relyra.Ecto.ConnectionSnapshot do
  @moduledoc false

  alias Relyra.{Connection, Error, Provider}

  @attribute_targets [:email, :first_name, :last_name, :display_name, :name_id]
  @multivalue_strategies [:first, :all]
  @group_targets [:role]

  @spec hydrate(struct(), keyword()) :: {:ok, Connection.t()} | {:error, Error.t()}
  def hydrate(connection, opts \\ [])

  def hydrate(%Relyra.Ecto.Connection{} = connection, opts) when is_list(opts) do
    operation = Keyword.get(opts, :operation, :resolve_connection)
    certificates = certificate_pems(connection)

    if certificates == [] do
      {:error,
       Error.new(
         :connection_invalid,
         "Persisted connection has no trusted certificates to hydrate",
         %{
           connection_id: connection.connection_id,
           operation: operation,
           reason: :missing_certificates
         }
       )}
    else
      with {:ok, mapping_config} <- normalize_mapping_config(connection, operation) do
        runtime_attrs =
          connection
          |> base_runtime_attrs()
          |> apply_provider_defaults(connection.provider_preset)
          |> Map.put(:idp_certificates, certificates)
          |> Map.put(:cert_chain, certificates)
          |> Map.put(:mapping_config, mapping_config)

        {:ok, struct(Connection, runtime_attrs)}
      end
    end
  rescue
    exception ->
      {:error,
       Error.new(
         :resolver_failed,
         "Persisted connection snapshot hydration failed",
         %{
           connection_id: Map.get(connection, :connection_id),
           operation: Keyword.get(opts, :operation, :resolve_connection),
           reason: :hydration_failed,
           failure: Exception.message(exception)
         }
       )}
  end

  def hydrate(connection, opts) do
    {:error,
     Error.new(
       :resolver_failed,
       "Persisted connection snapshot hydration received an invalid aggregate",
       %{
         connection: inspect(connection),
         operation: Keyword.get(opts, :operation, :resolve_connection),
         reason: :invalid_aggregate
       }
     )}
  end

  defp base_runtime_attrs(connection) do
    runtime_policy = Map.get(connection, :runtime_policy) || %{}

    %{
      id: connection.id,
      connection_id: connection.connection_id,
      idp_entity_id: connection.idp_entity_id,
      sp_entity_id: connection.sp_entity_id,
      acs_url: connection.acs_url,
      idp_sso_url: connection.idp_sso_url,
      name_id_format: Map.get(runtime_policy, :name_id_format),
      algorithm_policy: Map.get(runtime_policy, :algorithm_policy) || %{},
      allow_idp_initiated?: Map.get(runtime_policy, :allow_idp_initiated?),
      require_signed_assertions?: Map.get(runtime_policy, :require_signed_assertions?),
      require_signed_response?: Map.get(runtime_policy, :require_signed_response?),
      clock_skew_seconds: Map.get(runtime_policy, :clock_skew_seconds),
      provider_preset: connection.provider_preset,
      display_name: connection.display_name,
      organization_id: connection.organization_id
    }
  end

  defp apply_provider_defaults(attrs, nil), do: attrs

  defp apply_provider_defaults(attrs, provider_preset) do
    attrs
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.into([])
    |> then(&Provider.apply_defaults(provider_preset, &1))
    |> Map.new()
  end

  defp certificate_pems(connection) do
    connection
    |> Map.get(:certificates, [])
    |> Enum.filter(&active_signing_certificate?/1)
    |> Enum.sort_by(fn certificate ->
      {
        datetime_sort_value(
          Map.get(certificate, :activated_at) || Map.get(certificate, :inserted_at)
        ),
        datetime_sort_value(Map.get(certificate, :inserted_at))
      }
    end)
    |> Enum.map(&Map.get(&1, :pem))
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  defp active_signing_certificate?(certificate) do
    Map.get(certificate, :role, :signing) == :signing and
      Map.get(certificate, :lifecycle_state, :active) == :active
  end

  defp datetime_sort_value(nil), do: 0
  defp datetime_sort_value(%DateTime{} = datetime), do: DateTime.to_unix(datetime, :microsecond)

  defp normalize_mapping_config(connection, operation) do
    with {:ok, attribute_rules} <-
           normalize_attribute_rules(mapping_rows(connection, :attribute_mappings), operation),
         {:ok, group_rules} <-
           normalize_group_rules(mapping_rows(connection, :group_mappings), operation) do
      config = %{
        attribute_rules: attribute_rules,
        group_rules: group_rules
      }

      if attribute_rules == [] and group_rules == [] do
        {:ok, nil}
      else
        {:ok, config}
      end
    end
  end

  defp normalize_attribute_rules(rows, operation) when is_list(rows) do
    rows
    |> Enum.reduce_while({:ok, []}, fn row, {:ok, acc} ->
      case normalize_attribute_rule(row, operation) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, %Error{} = error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, rules} ->
        rules
        |> Enum.reverse()
        |> Enum.sort_by(fn rule ->
          {
            Map.fetch!(rule, :position),
            Map.fetch!(rule, :source_attribute),
            Map.fetch!(rule, :target_field)
          }
        end)
        |> Enum.map(&Map.delete(&1, :position))
        |> then(&{:ok, &1})

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp normalize_attribute_rules(_rows, operation),
    do: invalid_mapping_error(operation, :attribute_mappings, :invalid_collection)

  defp normalize_group_rules(rows, operation) when is_list(rows) do
    rows
    |> Enum.reduce_while({:ok, []}, fn row, {:ok, acc} ->
      case normalize_group_rule(row, operation) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, %Error{} = error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, rules} ->
        rules
        |> Enum.reverse()
        |> Enum.sort_by(fn rule ->
          {
            Map.fetch!(rule, :position),
            Map.fetch!(rule, :source_attribute),
            Map.fetch!(rule, :source_value),
            Map.fetch!(rule, :role_value)
          }
        end)
        |> Enum.map(&Map.delete(&1, :position))
        |> then(&{:ok, &1})

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp normalize_group_rules(_rows, operation),
    do: invalid_mapping_error(operation, :group_mappings, :invalid_collection)

  defp mapping_rows(connection, key) do
    case Map.get(connection, key) do
      nil -> []
      %Ecto.Association.NotLoaded{} -> []
      rows -> rows
    end
  end

  defp normalize_attribute_rule(row, operation) do
    with {:ok, position} <- fetch_position(row, operation, :attribute_mappings),
         {:ok, source_attribute} <-
           fetch_required_string(row, :source_attribute, operation, :attribute_mappings),
         {:ok, target_field} <-
           fetch_enum(row, :target_field, @attribute_targets, operation, :attribute_mappings),
         {:ok, multivalue_strategy} <-
           fetch_enum(
             row,
             :multivalue_strategy,
             @multivalue_strategies,
             operation,
             :attribute_mappings
           ) do
      {:ok,
       %{
         position: position,
         source_attribute: source_attribute,
         target_field: target_field,
         multivalue_strategy: multivalue_strategy
       }}
    end
  end

  defp normalize_group_rule(row, operation) do
    with {:ok, position} <- fetch_position(row, operation, :group_mappings),
         {:ok, source_attribute} <-
           fetch_required_string(row, :source_attribute, operation, :group_mappings),
         {:ok, source_value} <-
           fetch_required_string(row, :source_value, operation, :group_mappings),
         {:ok, role_target} <-
           fetch_enum(row, :role_target, @group_targets, operation, :group_mappings),
         {:ok, role_value} <-
           fetch_required_string(row, :role_value, operation, :group_mappings) do
      {:ok,
       %{
         position: position,
         source_attribute: source_attribute,
         source_value: source_value,
         role_target: role_target,
         role_value: role_value
       }}
    end
  end

  defp fetch_position(row, operation, mapping_type) do
    case Map.get(row, :position, Map.get(row, "position", 0)) do
      position when is_integer(position) and position >= 0 -> {:ok, position}
      _other -> invalid_mapping_error(operation, mapping_type, :invalid_position)
    end
  end

  defp fetch_required_string(row, key, operation, mapping_type) do
    value =
      row
      |> Map.get(key, Map.get(row, Atom.to_string(key)))
      |> normalize_string()

    if is_binary(value) and value != "" do
      {:ok, value}
    else
      invalid_mapping_error(operation, mapping_type, {:missing_field, key})
    end
  end

  defp fetch_enum(row, key, allowed, operation, mapping_type) do
    value =
      row
      |> Map.get(key, Map.get(row, Atom.to_string(key)))
      |> normalize_enum()

    if value in allowed do
      {:ok, value}
    else
      invalid_mapping_error(operation, mapping_type, {:invalid_field, key})
    end
  end

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(nil), do: nil
  defp normalize_string(value), do: value |> to_string() |> normalize_string()

  defp normalize_enum(value) when is_atom(value), do: value

  defp normalize_enum(value) when is_binary(value) do
    case String.trim(value) do
      "" ->
        nil

      normalized ->
        try do
          String.to_existing_atom(normalized)
        rescue
          ArgumentError -> nil
        end
    end
  end

  defp normalize_enum(_value), do: nil

  defp invalid_mapping_error(operation, mapping_type, reason) do
    {:error,
     Error.new(
       :connection_invalid,
       "Persisted connection has invalid mapping configuration",
       %{
         operation: operation,
         reason: :invalid_mapping_config,
         mapping_type: mapping_type,
         invalid_detail: reason
       }
     )}
  end
end
