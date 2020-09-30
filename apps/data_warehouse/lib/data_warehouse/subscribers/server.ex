defmodule DataWarehouse.Subscribers.Server do
  use GenServer

  require Logger

  defmodule State do
    # topic => WorkerData
    defstruct workers: %{}
  end

  defmodule WorkerData do
    @enforce_keys [:pid, :ref, :stream_name, :symbol]
    defstruct [:pid, :ref, :stream_name, :symbol]
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    {:ok, %State{}}
  end

  def start_storing(stream_name, symbol) do
    GenServer.cast(__MODULE__, {:start_storing, stream_name, symbol})
  end

  def handle_cast({:start_storing, stream_name, symbol}, state) do
    stream_name = String.downcase(stream_name)
    symbol = String.downcase(symbol)
    key = "#{stream_name}:#{symbol}"

    workers =
      if !Map.has_key?(state.workers, key) do
        Logger.info("Starting new worker to store #{key} data")
        result = start_worker(stream_name, symbol)
        Map.put(state.workers, key, result)
      else
        Logger.info("Worker already started for #{key} data")
        state.workers
      end

    {:noreply, %{state | workers: workers}}
  end

  def handle_info(
        {:DOWN, _ref, :process, worker_pid, _reason},
        %{workers: workers} = state
      ) do
    workers_list = workers |> Map.to_list()

    case Enum.find_index(workers_list, &(elem(&1, 1).pid == worker_pid)) do
      nil ->
        Logger.warn("Tried to restart unknown subscriber worker")
        {:noreply, state}

      index ->
        {topic, worker_data} = Enum.at(workers_list, index)

        Logger.warn("Subscriber worker(#{topic}) died, restarting")

        new_worker_data = start_worker(worker_data.stream_name, worker_data.symbol)

        new_workers_list =
          List.replace_at(
            workers_list,
            index,
            {topic, new_worker_data}
          )

        {:noreply, %{state | workers: Map.new(new_workers_list)}}
    end
  end

  defp start_worker(stream_name, symbol) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        DataWarehouse.Subscribers.DynamicSupervisor,
        {DataWarehouse.Subscribers.Worker,
         %{
           stream_name: stream_name,
           symbol: symbol
         }}
      )

    ref = Process.monitor(pid)

    %WorkerData{
      pid: pid,
      ref: ref,
      stream_name: stream_name,
      symbol: symbol
    }
  end
end
