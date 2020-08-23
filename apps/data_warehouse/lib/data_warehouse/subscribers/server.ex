defmodule DataWarehouse.Subscribers.Server do
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
    stream = String.downcase(stream)
    symbol = String.downcase(symbol)
    key = "#{stream}:#{symbol}"
    workers = if !Map.has_key?(state.workers, key) do
      Logger.info("Starting new worker to store #{key} data")
      result = start_worker(stream, symbol)
      Map.put(state.workers, key, result)
    else
      Logger.info("Worker already started for #{key} data")
      state.workers
    end

    {:noreply, %{state | workers: workers}}
  end

  defp start_worker(stream, symbol) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        DataWarehouse.Subscribers.DynamicSupervisor,
        {DataWarehouse.Subscribers.Worker, %{
          stream: stream,
          symbol: symbol
        }}
      )

    ref = Process.monitor(pid)

    {pid, ref}
  end
end