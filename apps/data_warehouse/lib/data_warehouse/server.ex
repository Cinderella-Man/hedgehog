defmodule DataWarehouse.Server do
  use GenServer

  require Logger

  defmodule State do
    defstruct workers: %{}
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    {:ok, %State{}}
  end

  def start_storing(stream, symbol) do
    GenServer.cast(__MODULE__, {:start_storing, stream, symbol})
  end

  def handle_cast({:start_storing, stream, symbol}, state) do
    Logger.info("Starting new worker to store #{stream}@#{symbol}")
    result = start_worker(stream, symbol)
    workers = Map.put(state.workers, "#{stream}-#{symbol}", result)
    {:noreply, %{state | workers: workers}}
  end

  defp start_worker(stream, symbol) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        DataWarehouse.DynamicSupervisor,
        {DataWarehouse.Worker, %{
          stream: stream,
          symbol: symbol
        }}
      )

    ref = Process.monitor(pid)

    {pid, ref}
  end
end