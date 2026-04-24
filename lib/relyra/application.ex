defmodule Relyra.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Relyra.Application.StoreTables
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Relyra.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule Relyra.Application.StoreTables do
  @moduledoc false

  use GenServer

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  @spec init(keyword()) :: {:ok, map()}
  def init(opts) do
    :ok = Relyra.RequestStore.ETS.ensure_table!(opts)
    :ok = Relyra.ReplayStore.ETS.ensure_table!(opts)
    {:ok, %{}}
  end
end
