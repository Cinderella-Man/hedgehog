defmodule Streamer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Streamer.Repo, []},
      {
        Phoenix.PubSub,
        name: Streamer.PubSub, adapter_name: Phoenix.PubSub.PG2
      },
      {Streamer.Supervisor, []}
      # Starts a worker by calling: Streamer.Worker.start_link(arg)
      # {Streamer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Streamer.Application]
    Supervisor.start_link(children, opts)
  end
end
