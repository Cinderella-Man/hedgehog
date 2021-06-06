defmodule Hedgehog.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp aliases do
    [
      setup: [
        "ecto.drop",
        "ecto.create",
        "ecto.migrate",
        "cmd --app naive --app streamer mix seed"
      ],
      "test.integration": &integration_test/1
    ]
  end

  defp integration_test(_) do
    Mix.env(:test)
    Mix.Task.run("setup")
    Mix.Task.run("test", ["--only", "integration"])
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end
end
