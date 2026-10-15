defmodule PackageConsumer.Relyra.UserMapper do
  @moduledoc false
  @behaviour Relyra.UserMapper

  @impl true
  def map_attributes(login_result, _connection, _opts) do
    user_id = login_result.principal.name_id
    {:ok, %{id: user_id, email: user_id}}
  end
end
