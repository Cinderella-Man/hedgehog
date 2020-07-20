defmodule Naive.Server do
  use GenServer

  require Logger

  defmodule State do
    defstruct symbol_supervisors: %{}
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    {:ok, %State{}}
  end

  def start_trading(symbol) do
    GenServer.cast(__MODULE__, {:start_trading, symbol})
  end

  def handle_cast({:start_trading, symbol}, state) do
    Logger.info("Starting new supervision tree to trade on #{symbol}")
    result = start_symbol_supervisor(symbol)
    symbol_supervisors = Map.put(state.symbol_supervisors, symbol, result)
    {:noreply, %{state | symbol_supervisors: symbol_supervisors}}
  end

  defp start_symbol_supervisor(symbol) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        Naive.DynamicSupervisor,
        {Naive.SymbolSupervisor, symbol}
      )

    ref = Process.monitor(pid)

    {pid, ref}
  end
end
