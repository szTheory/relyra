Code.require_file("lib/mix/tasks/compile/parser_path_guard.ex", __DIR__)

defmodule Relyra.MixProject do
  use Mix.Project

  def project do
    [
      app: :relyra,
      version: "0.1.0",
      elixir: "~> 1.19",
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
        "ci.integration": :test
      ]
    ]
  end

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
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.13", optional: true},
      {:ecto_sql, "~> 3.13", optional: true},
      {:postgrex, ">= 0.0.0", optional: true}
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
      "ci.integration": [
        "test --only integration --warnings-as-errors"
      ]
    ]
  end
end
