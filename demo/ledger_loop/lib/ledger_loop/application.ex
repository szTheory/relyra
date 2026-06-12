defmodule LedgerLoop.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LedgerLoopWeb.Telemetry,
      LedgerLoop.Repo,
      {DNSCluster, query: Application.get_env(:ledger_loop, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LedgerLoop.PubSub},
      # Start a worker by calling: LedgerLoop.Worker.start_link(arg)
      # {LedgerLoop.Worker, arg},
      # Start to serve requests, typically the last entry
      LedgerLoopWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LedgerLoop.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LedgerLoopWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
