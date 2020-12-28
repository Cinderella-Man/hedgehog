defmodule Naive.Server do
  use GenServer

  require Logger

  import Ecto.Query, only: [from: 2]

  alias Naive.Repo
  alias Naive.Schema

  defmodule State do
    defstruct symbol_supervisors: %{}
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    {:ok, %State{}, {:continue, :start_trading}}
  end

  def start_trading(symbol) do
    symbol = String.upcase(symbol)
    GenServer.cast(__MODULE__, {:start_trading, symbol})
  end

  def stop_trading(symbol) do
    symbol = String.upcase(symbol)
    GenServer.cast(__MODULE__, {:stop_trading, symbol})
  end

  def shutdown_trading(symbol) do
    symbol = String.upcase(symbol)
    GenServer.cast(__MODULE__, {:shutdown_trading, symbol})
  end

  def handle_continue(:start_trading, _state) do
    symbol_supervisors =
      fetch_symbols_to_trade()
      |> Enum.map(&{&1, start_symbol_supervisor(&1)})
      |> Enum.into(%{})

    {:noreply, %State{symbol_supervisors: symbol_supervisors}}
  end

  def handle_cast({:start_trading, symbol}, state) do
    new_symbol_supervisors =
      case Map.get(state.symbol_supervisors, symbol) do
        nil ->
          Logger.info("Starting new supervision tree to trade on #{symbol}")
          result = start_symbol_supervisor(symbol)
          {:ok, _settings} = update_trading_status(symbol, "on")
          Map.put(state.symbol_supervisors, symbol, result)

        _ ->
          Logger.warn("Trading on #{symbol} already started")
          state.symbol_supervisors
      end

    {:noreply, %{state | symbol_supervisors: new_symbol_supervisors}}
  end

  def handle_cast({:stop_trading, symbol}, state) do
    new_symbol_supervisors =
      case Map.get(state.symbol_supervisors, symbol) do
        {pid, ref} ->
          Logger.info("Stopping trading on #{symbol}")
          {:ok, _settings} = update_trading_status(symbol, "off")
          Process.demonitor(ref)
          Process.exit(pid, :kill)
          Map.delete(state.symbol_supervisors, symbol)

        _ ->
          Logger.warn("Trading on #{symbol} already stopped")
          state.symbol_supervisors
      end

    {:noreply, %{state | symbol_supervisors: new_symbol_supervisors}}
  end

  def handle_cast({:shutdown_trading, symbol}, state) do
    case Map.get(state.symbol_supervisors, symbol) do
      {_pid, _ref} ->
        Logger.info("Shutting down trading on #{symbol}")
        {:ok, settings} = update_trading_status(symbol, "shutdown")
        Naive.Leader.notify(:settings_updated, settings)

      _ ->
        Logger.warn("Trading on #{symbol} already stopped")
    end

    {:noreply, state}
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

  defp fetch_symbols_to_trade() do
    Repo.all(
      from(s in Schema.Settings,
        where: s.status == "on",
        select: s.symbol
      )
    )
  end

  defp update_trading_status(symbol, status)
       when is_binary(status) do
    Repo.get_by(Schema.Settings, symbol: symbol)
    |> Ecto.Changeset.change(%{status: status})
    |> Repo.update()
  end
end
