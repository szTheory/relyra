import Config

database_url = System.get_env("RELYRA_TEST_DATABASE_URL") || System.get_env("DATABASE_URL")

repo_config =
  if database_url do
    [
      url: database_url,
      pool: Ecto.Adapters.SQL.Sandbox,
      migration_primary_key: [type: :binary_id],
      migration_timestamps: [type: :utc_datetime_usec]
    ]
  else
    base_config = [
      username: System.get_env("PGUSER") || System.get_env("USER") || "postgres",
      password: System.get_env("PGPASSWORD"),
      database: System.get_env("RELYRA_TEST_DATABASE") || "relyra_test",
      port: String.to_integer(System.get_env("PGPORT") || "5432"),
      pool: Ecto.Adapters.SQL.Sandbox,
      migration_primary_key: [type: :binary_id],
      migration_timestamps: [type: :utc_datetime_usec]
    ]

    case System.get_env("PGHOST") do
      nil ->
        Keyword.put(base_config, :socket_dir, System.get_env("PGSOCKET") || "/tmp")

      hostname ->
        Keyword.put(base_config, :hostname, hostname)
    end
  end

config :relyra, ecto_repos: [Relyra.TestSupport.EctoTestRepo]
# Query logging stays off in tests: debug query lines echo fixture certificate
# PEMs into captured command output, which the Phase 78 diagnostics validator
# (correctly) rejects as certificate material.
config :relyra, Relyra.TestSupport.EctoTestRepo, Keyword.put(repo_config, :log, false)

config :relyra, Relyra.TestSupport.LiveAdminEndpoint,
  url: [host: "127.0.0.1"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [html: Relyra.TestSupport.LiveAdminErrorHTML], layout: false],
  pubsub_server: Relyra.TestSupport.LiveAdminPubSub,
  secret_key_base: String.duplicate("a", 64),
  live_view: [signing_salt: "live-admin-signing-salt"],
  server: false
