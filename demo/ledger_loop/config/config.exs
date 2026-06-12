# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ledger_loop,
  ecto_repos: [LedgerLoop.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :ledger_loop, LedgerLoopWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: LedgerLoopWeb.ErrorHTML, json: LedgerLoopWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LedgerLoop.PubSub,
  live_view: [signing_salt: "Uo7fHsbv"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :relyra,
  connection_resolver: Relyra.ConnectionResolver.Ecto,
  request_store: LedgerLoop.Relyra.RequestStore,
  replay_store: LedgerLoop.Relyra.ReplayStore,
  user_mapper: LedgerLoop.Relyra.UserMapper,
  session_adapter: LedgerLoop.Relyra.SessionAdapter,
  repo: LedgerLoop.Repo

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
