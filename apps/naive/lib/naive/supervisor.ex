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
        {Naive.DynamicSymbolSupervisor, []},
        {Task,
         fn ->
           Naive.DynamicSymbolSupervisor.autostart_workers()
         end}
      ],
      strategy: :rest_for_one
    )
  end
end
