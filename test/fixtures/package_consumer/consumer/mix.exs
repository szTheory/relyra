defmodule PackageConsumer.MixProject do
  use Mix.Project

  def project do
    [
      app: :package_consumer,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: if(minimal_profile?(), do: [], else: ["lib"]),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {PackageConsumer.Application, []}]
  end

  defp deps do
    relyra = {:relyra, path: System.fetch_env!("PACKAGE_CONSUMER_RELYRA_PATH")}

    if minimal_profile?() do
      [relyra]
    else
      [
        relyra,
        {:phoenix, "~> 1.8"},
        {:phoenix_ecto, "~> 4.6"},
        {:ecto_sql, "~> 3.13"},
        {:postgrex, ">= 0.0.0"},
        {:req, "~> 0.5"}
      ]
    end
  end

  defp minimal_profile?, do: System.get_env("PACKAGE_CONSUMER_PROFILE") == "minimal"
end
