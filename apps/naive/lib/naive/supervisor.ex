defmodule Naive.Supervisor do
  use Supervisor, restart: :temporary

  def start_link(_) do
    Supervisor.start_link(
      __MODULE__,
      [],
      name: __MODULE__
    )
  end

  def init(_) do
    Supervisor.init(
      [
        {
          DynamicSupervisor,
          strategy: :one_for_one, name: Naive.DynamicSupervisor
        },
        {Naive.Server, []}
      ],
      strategy: :one_for_all
    )
  end
end
