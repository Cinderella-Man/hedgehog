defmodule Naive.MixProject do
  use Mix.Project

  def project do
    [
      app: :naive,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp aliases do
    [
      seed: ["run priv/seed_settings.exs"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Naive.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:binance, "~> 0.7"},
      {:decimal, "~> 2.0"},
      {:ecto_sql, "~> 3.0"},
      {:ecto_enum, "~> 1.4"},
      {:mox, "~> 1.0", only: [:test, :integration]},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:binance_mock, in_umbrella: true},
      {:core, in_umbrella: true},
      {:data_warehouse, in_umbrella: true, only: :test}
    ]
  end
end
