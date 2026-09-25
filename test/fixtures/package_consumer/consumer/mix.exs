defmodule PackageConsumer.MixProject do
  use Mix.Project

  def project do
    [
      app: :package_consumer,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {PackageConsumer.Application, []}]
  end

  defp deps do
    [
      {:relyra, path: System.fetch_env!("PACKAGE_CONSUMER_RELYRA_PATH")},
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.6"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:req, "~> 0.5"}
    ]
  end
end
