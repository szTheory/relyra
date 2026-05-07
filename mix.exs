Code.require_file("lib/mix/tasks/compile/parser_path_guard.ex", __DIR__)

defmodule Relyra.MixProject do
  use Mix.Project

  def project do
    [
      app: :relyra,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      compilers: [:parser_path_guard] ++ Mix.compilers(),
      elixirc_options: [ignore_module_conflict: true],
      aliases: aliases(),
      deps: deps()
    ]
  end

  def cli do
    [
      preferred_envs: [
        qa: :test,
        "ci.fast": :test,
        "ci.security": :test,
        "ci.verify": :test,
        "ci.integration": :test,
        "ci.oban_smoke": :test,
        "ci.release": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Relyra.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:telemetry, "~> 1.3"},
      {:plug, "~> 1.16"},
      {:phoenix, "~> 1.8", optional: true},
      {:phoenix_live_view, "~> 1.1", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.13", optional: true},
      {:ecto_sql, "~> 3.13", optional: true},
      {:postgrex, ">= 0.0.0", optional: true},
      {:req, "~> 0.5", optional: true},
      {:oban, "~> 2.22", optional: true}
    ]
  end

  defp aliases do
    [
      qa: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "credo --strict",
        "test --warnings-as-errors"
      ],
      "ci.fast": [
        "compile --warnings-as-errors",
        "test --warnings-as-errors --exclude integration"
      ],
      "ci.security": [
        "test --only security_corpus --warnings-as-errors",
        "test --only gate02_c14n --warnings-as-errors",
        "deps.audit",
        "hex.audit",
        "sobelow --config"
      ],
      "ci.verify": [
        "test test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/mapping_commands_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs --warnings-as-errors"
      ],
      "ci.integration": [
        "test --only integration --warnings-as-errors"
      ],
      "ci.oban_smoke": [
        "compile --no-optional-deps --warnings-as-errors",
        "compile --warnings-as-errors",
        "test --include oban --warnings-as-errors test/relyra/optional_deps/oban_test.exs test/relyra/workers/metadata_refresh_test.exs"
      ],
      "ci.release": [
        "test test/release/release_hardening_test.exs --warnings-as-errors"
      ]
    ]
  end
end
