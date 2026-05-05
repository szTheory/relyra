defmodule Relyra.UserMapper.DefaultAttribute do
  @moduledoc false
  @behaviour Relyra.UserMapper

  @impl true
  def map_attributes(assertion, connection, _opts \\ []) do
    attributes = Map.get(assertion, :attributes) || %{}

    user_map =
      case Map.get(connection, :mapping_config) do
        %{attribute_rules: attribute_rules, group_rules: group_rules} ->
          persisted_user_map(assertion, attributes, attribute_rules, group_rules)

        _other ->
          fallback_user_map(assertion, attributes)
      end

    {:ok, user_map}
  end

  defp get_attribute(attributes, candidates) do
    Enum.find_value(candidates, fn key ->
      Map.get(attributes, key) || Map.get(attributes, String.to_atom(key))
    end)
  end

  defp fallback_user_map(assertion, attributes) do
    %{
      name_id: Map.get(assertion, :name_id),
      email: get_attribute(attributes, ["email", "mail", "EmailAddress"]),
      first_name: get_attribute(attributes, ["given_name", "givenname", "FirstName"]),
      last_name: get_attribute(attributes, ["family_name", "sn", "LastName"]),
      roles: get_attribute(attributes, ["groups", "roles", "memberOf"]) || []
    }
  end

  defp persisted_user_map(assertion, attributes, attribute_rules, group_rules) do
    initial_map = %{
      name_id: Map.get(assertion, :name_id),
      email: nil,
      first_name: nil,
      last_name: nil,
      display_name: nil,
      roles: []
    }

    initial_map
    |> apply_attribute_rules(attributes, attribute_rules)
    |> Map.put(:roles, apply_group_rules(attributes, group_rules))
  end

  defp apply_attribute_rules(user_map, attributes, rules) when is_list(rules) do
    Enum.reduce(rules, user_map, fn rule, acc ->
      source_attribute = Map.get(rule, :source_attribute)
      target_field = Map.get(rule, :target_field)
      strategy = Map.get(rule, :multivalue_strategy)

      case resolve_attribute(attributes, source_attribute, strategy) do
        nil -> acc
        value -> Map.put(acc, target_field, value)
      end
    end)
  end

  defp apply_attribute_rules(user_map, _attributes, _rules), do: user_map

  defp apply_group_rules(attributes, rules) when is_list(rules) do
    rules
    |> Enum.reduce([], fn rule, acc ->
      values = normalize_attribute_values(fetch_exact_attribute(attributes, Map.get(rule, :source_attribute)))

      if Enum.any?(values, &(&1 == Map.get(rule, :source_value))) and Map.get(rule, :role_target) == :role do
        acc ++ [Map.get(rule, :role_value)]
      else
        acc
      end
    end)
    |> Enum.reject(&is_nil_or_blank/1)
    |> Enum.uniq()
  end

  defp apply_group_rules(_attributes, _rules), do: []

  defp resolve_attribute(attributes, source_attribute, :first) do
    attributes
    |> fetch_exact_attribute(source_attribute)
    |> normalize_attribute_values()
    |> List.first()
  end

  defp resolve_attribute(attributes, source_attribute, :all) do
    values =
      attributes
      |> fetch_exact_attribute(source_attribute)
      |> normalize_attribute_values()

    case values do
      [] -> nil
      _values -> values
    end
  end

  defp resolve_attribute(_attributes, _source_attribute, _strategy), do: nil

  defp fetch_exact_attribute(attributes, key) when is_binary(key) do
    Map.get(attributes, key) || Map.get(attributes, String.to_atom(key))
  end

  defp normalize_attribute_values(value) when is_list(value) do
    value
    |> Enum.map(&normalize_attribute_value/1)
    |> Enum.reject(&is_nil_or_blank/1)
  end

  defp normalize_attribute_values(value) do
    case normalize_attribute_value(value) do
      nil -> []
      normalized -> [normalized]
    end
  end

  defp normalize_attribute_value(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_attribute_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_attribute_value(value) when is_nil(value), do: nil
  defp normalize_attribute_value(value), do: to_string(value)

  defp is_nil_or_blank(nil), do: true
  defp is_nil_or_blank(""), do: true
  defp is_nil_or_blank(_value), do: false
end
