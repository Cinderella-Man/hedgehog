defmodule DataWarehouse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {DataWarehouse.Subscribers.Supervisor, []},
      {DataWarehouse.Repo, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DataWarehouse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
