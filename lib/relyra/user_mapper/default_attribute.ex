defmodule Relyra.UserMapper.DefaultAttribute do
  @moduledoc false
  @behaviour Relyra.UserMapper

  @impl true
  def map_attributes(assertion, _connection, _opts \\ []) do
    attributes = Map.get(assertion, :attributes) || %{}
    
    user_map = %{
      name_id: Map.get(assertion, :name_id),
      email: get_attribute(attributes, ["email", "mail", "EmailAddress"]),
      first_name: get_attribute(attributes, ["given_name", "givenname", "FirstName"]),
      last_name: get_attribute(attributes, ["family_name", "sn", "LastName"]),
      roles: get_attribute(attributes, ["groups", "roles", "memberOf"]) || []
    }

    {:ok, user_map}
  end

  defp get_attribute(attributes, candidates) do
    Enum.find_value(candidates, fn key ->
      Map.get(attributes, key) || Map.get(attributes, String.to_atom(key))
    end)
  end
end
