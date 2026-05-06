defmodule Relyra.LiveAdmin do
  @moduledoc """
  Optional LiveView admin surface helpers.
  """

  @live_view_modules [Phoenix.LiveView, Phoenix.LiveView.Router]

  @spec available?() :: boolean()
  def available? do
    Enum.all?(@live_view_modules, &Code.ensure_loaded?/1)
  end

  @spec ensure_available!() :: :ok
  def ensure_available! do
    if available?() do
      :ok
    else
      raise ArgumentError, missing_dependency_message()
    end
  end

  @spec missing_dependency_message() :: String.t()
  def missing_dependency_message do
    """
    [Relyra] Live admin requires Phoenix LiveView.

    Add the optional dependency to the host application:

        {:phoenix_live_view, "~> 1.1"}

    Then mount `Relyra.LiveAdmin.Router` inside a LiveView-enabled Phoenix app.
    """
  end
end
