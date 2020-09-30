defmodule DataWarehouse.Subscribers.Supervisor do
  use Supervisor

  def start_link(_args) do
    Supervisor.start_link(
      __MODULE__,
      nil,
      name: __MODULE__
    )
  end

  def init(_args) do
    Supervisor.init(
      [
        {
          DynamicSupervisor,
          strategy: :one_for_one, name: DataWarehouse.Subscribers.DynamicSupervisor
        },
        {DataWarehouse.Subscribers.Server, []}
      ],
      strategy: :one_for_all
    )
  end
end
