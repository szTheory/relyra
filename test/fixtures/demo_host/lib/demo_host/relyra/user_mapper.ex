defmodule DemoHost.Relyra.UserMapper do
  @moduledoc false
  @behaviour Relyra.UserMapper

  @impl true
  def map_attributes(%{principal: principal}, _connection, _opts) do
    {:ok,
     %{
       id: principal.name_id,
       email: principal.name_id,
       name_id: principal.name_id
     }}
  end
end
