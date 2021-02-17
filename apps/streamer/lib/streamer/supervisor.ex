defmodule Streamer.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    children = [
      {Streamer.DynamicStreamerSupervisor, []},
      {Task,
       fn ->
         Streamer.DynamicStreamerSupervisor.autostart_streaming()
       end}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end