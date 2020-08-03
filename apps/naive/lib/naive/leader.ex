defmodule Naive.Leader do
  use GenServer
  alias Naive.Trader
  alias Decimal, as: D

  require Logger

  defmodule State do
    defstruct symbol: nil,
              settings: nil,
              traders: []
  end

  defmodule TraderData do
    defstruct pid: nil,
              ref: nil,
              state: nil
  end

  def start_link(symbol) do
    GenServer.start_link(
      __MODULE__,
      symbol,
      name: :"#{__MODULE__}-#{symbol}"
    )
  end

  def init(symbol) do
    {:ok,
     %State{
       symbol: symbol
     }, {:continue, :start_traders}}
  end

  def notify(:trader_state_updated, state) do
    GenServer.call(
      :"#{__MODULE__}-#{state.symbol}",
      {:update_trader_state, state}
    )
  end

  def handle_continue(:start_traders, %{symbol: symbol} = state) do
    settings = fetch_symbol_settings(symbol)

    trader_state = %Trader.State{
      symbol: symbol,
      budget: D.div(
        D.cast(settings.budget),
        D.cast(settings.chunks)
      ),
      buy_down_interval: settings.buy_down_interval,
      profit_interval: settings.profit_interval,
      tick_size: settings.tick_size,
      step_size: settings.step_size
    }

    traders =
      for _i <- 1..settings.chunks,
          do: start_new_trader(trader_state)

    {:noreply, %{state | settings: settings, traders: traders}}
  end

  def handle_call(
        {:update_trader_state, new_trader_state},
        {trader_pid, _},
        %{traders: traders} = state
      ) do
    case Enum.find_index(traders, &(&1.pid == trader_pid)) do
      nil ->
        Logger.warn("Tried to update the state of trader that leader is not aware of")
        {:reply, :ok, state}

      index ->
        old_trader_data = Enum.at(traders, index)
        new_trader_data = %{old_trader_data | :state => new_trader_state}

        {:reply, :ok, %{state | :traders => List.replace_at(traders, index, new_trader_data)}}
    end
  end

  def handle_info(
        {:DOWN, _ref, :process, trader_pid, :trade_finished},
        %{traders: traders} = state
      ) do
    Logger.info("Trader finished - restarting")

    case Enum.find_index(traders, &(&1.pid == trader_pid)) do
      nil ->
        Logger.warn("Tried to remove finished trader that leader is not aware of")
        {:noreply, state}

      index ->
        trader_data = Enum.at(traders, index)

        new_trader_data =
          start_new_trader(%{
            trader_data.state
            | buy_order: nil,
              sell_order: nil
          })

        new_traders = List.replace_at(traders, index, new_trader_data)

        {:noreply, %{state | traders: new_traders}}
    end
  end

  def handle_info(
        {:DOWN, _ref, :process, trader_pid, _reason},
        %{traders: traders} = state
      ) do
    Logger.error("Trader died - trying to restart")

    case Enum.find_index(traders, &(&1.pid == trader_pid)) do
      nil ->
        Logger.warn("Tried to restart trader but failed to find its cached state")
        {:noreply, state}

      index ->
        trader_data = Enum.at(traders, index)
        new_trader_data = start_new_trader(trader_data.state)
        new_traders = List.replace_at(traders, index, new_trader_data)

        {:noreply, %{state | traders: new_traders}}
    end
  end

  defp fetch_symbol_settings(symbol) do
    symbol_filters = fetch_symbol_filters(symbol)

    Map.merge(%{
      chunks: 1,
      budget: 20,
      # 0.5%
      buy_down_interval: 0.005,
      # 0.5%
      profit_interval: 0.005
    }, symbol_filters)
  end

  defp start_new_trader(%Trader.State{} = state) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        :"Naive.DynamicSupervisor-#{state.symbol}",
        {Naive.Trader, state}
      )

    ref = Process.monitor(pid)

    %TraderData{pid: pid, ref: ref, state: state}
  end

  defp fetch_symbol_filters(symbol) do
    %{"filters" => filters} =
      Binance.get_exchange_info()
      |> elem(1)
      |> Map.get(:symbols)
      |> Enum.find(&(&1["symbol"] == String.upcase(symbol)))

    %{"tickSize" => tick_size} =
      filters
      |> Enum.find(&(&1["filterType"] == "PRICE_FILTER"))

    %{"stepSize" => step_size} =
      filters
      |> Enum.find(&(&1["filterType"] == "LOT_SIZE"))

    %{
      tick_size: tick_size,
      step_size: step_size
    }
  end
end
