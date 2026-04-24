defmodule Relyra.MixProject do
  use Mix.Project

  def project do
    [
      app: :relyra,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
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
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false}
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
