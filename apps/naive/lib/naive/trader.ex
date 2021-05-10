defmodule Naive.Trader do
  use GenServer, restart: :temporary

  alias Decimal, as: D

  require Logger

  defmodule State do
    @enforce_keys [
      :id,
      :symbol,
      :budget,
      :buy_down_interval,
      :profit_interval,
      :rebuy_interval,
      :rebuy_notified,
      :tick_size,
      :step_size
    ]
    defstruct [
      :id,
      :symbol,
      :budget,
      :buy_order,
      :sell_order,
      :buy_down_interval,
      :profit_interval,
      :rebuy_interval,
      :rebuy_notified,
      :tick_size,
      :step_size
    ]
  end

  def start_link(%State{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(%State{} = state) do
    Phoenix.PubSub.subscribe(
      Streamer.PubSub,
      "TRADE_EVENTS:#{state.symbol}"
    )
    
    {:ok, state}
  end

  def handle_info(
    %Streamer.Binance.TradeEvent{price: price},
    %State{
      id: id,
      symbol: symbol,
      budget: budget,
      buy_order: nil,
      buy_down_interval: buy_down_interval,
      tick_size: tick_size,
      step_size: step_size
    } = state
  ) do
    price = calculate_buy_price(price, buy_down_interval, tick_size)
    quantity = calculate_quantity(budget, price, step_size)

    Logger.info(
      "The trader(#{id}) is placing a BUY order " <>
        "for #{symbol} @ #{price}, quantity: #{quantity}"
    )

    {:ok, %Binance.OrderResponse{} = order} =
      Binance.order_limit_buy(symbol, quantity, price, "GTC")

    new_state = %{state | buy_order: order}
    Naive.Leader.notify(:trader_state_updated, new_state)
    {:noreply, new_state}
  end

  def handle_info(
    %Streamer.Binance.TradeEvent{
      buyer_order_id: order_id,
      quantity: traded_quantity
    },
    %State{
      id: id,
      symbol: symbol,
      buy_order:
        %Binance.OrderResponse{
          price: buy_price,
          order_id: order_id,
          orig_qty: original_quantity,
          executed_qty: executed_quantity
        } = buy_order,
      profit_interval: profit_interval,
      tick_size: tick_size
    } = state
  ) do
    buy_order = %{buy_order | executed_qty:
      D.add(
        executed_quantity,
        traded_quantity
      )}

    {:ok, new_state} =
      if D.eq?(buy_order.executed_qty, original_quantity) do
        sell_price = calculate_sell_price(
          buy_price,
          profit_interval,
          tick_size
        )

        Logger.info(
          "The trader(#{id}) is placing a SELL order for " <>
            "#{symbol} @ #{sell_price}, quantity: #{original_quantity}."
        )

        {:ok, %Binance.OrderResponse{} = order} =
          Binance.order_limit_sell(
            symbol,
            original_quantity,
            sell_price,
            "GTC"
          )

        {:ok, %{state | buy_order: buy_order, sell_order: order}}
      else
        Logger.info("Trader's(#{id}) #{symbol} buy order got partially filled")
        {:ok, %{state | buy_order: buy_order}}
      end

    Naive.Leader.notify(:trader_state_updated, new_state)
    {:noreply, new_state}
  end

  def handle_info(
    %Streamer.Binance.TradeEvent{
      seller_order_id: order_id,
      quantity: traded_quantity
    },
    %State{
      id: id,
      symbol: symbol,
      sell_order:
      %Binance.OrderResponse{
        order_id: order_id,
        orig_qty: original_quantity,
        executed_qty: executed_quantity
      } = sell_order
    } = state
  ) do
    sell_order = %{sell_order | executed_qty:
      D.add(
        executed_quantity,
        traded_quantity
      )}

    if D.eq?(sell_order.executed_qty, original_quantity) do
      Logger.info("Trader(#{id}) finished trade cycle for #{symbol}")
      {:stop, :normal, state}
    else
      Logger.info("Trader's(#{id}) #{symbol} SELL order got partially filled")
      new_state = %{state | sell_order: sell_order}
      Naive.Leader.notify(:trader_state_updated, new_state)
      {:noreply, new_state}
    end
  end

  def handle_info(
    %Streamer.Binance.TradeEvent{
      price: current_price
    },
    %State{
      id: id,
      symbol: symbol,
      buy_order: %Binance.OrderResponse{
        price: buy_price
      },
      rebuy_interval: rebuy_interval,
      rebuy_notified: false
    } = state
  ) do
    if trigger_rebuy?(buy_price, current_price, rebuy_interval) do
      Logger.info("Rebuy triggered for #{symbol} by the trader(#{id})")
      new_state = %{state | rebuy_notified: true}
      Naive.Leader.notify(:rebuy_triggered, new_state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  def handle_info(%Streamer.Binance.TradeEvent{}, state) do
    {:noreply, state}
  end

  defp calculate_buy_price(price, buy_down_interval, tick_size) do
    current_price = D.new(price)

    # not necessarily legal price
    exact_buy_price =
      D.sub(
        current_price,
        D.mult(current_price, buy_down_interval)
      )

    D.to_float(
      D.mult(
        D.div_int(exact_buy_price, tick_size),
        tick_size
      )
    )
  end

  defp calculate_quantity(budget, price, step_size) do
    price = D.from_float(price)

    # not necessarily legal quantity
    exact_target_quantity = D.div(budget, price)

    D.to_float(
      D.mult(
        D.div_int(exact_target_quantity, step_size),
        step_size
      )
    )
  end

  defp calculate_sell_price(buy_price, profit_interval, tick_size) do
    fee = D.new("1.001")
    original_price = D.mult(D.new(buy_price), fee)

    net_target_price =
      D.mult(
        original_price,
        D.add("1.0", profit_interval)
      )

    gross_target_price = D.mult(net_target_price, fee)

    D.to_float(
      D.mult(
        D.div_int(gross_target_price, tick_size),
        tick_size
      )
    )
  end

  defp trigger_rebuy?(buy_price, current_price, rebuy_interval) do
    current_price = D.new(current_price)
    buy_price = D.new(buy_price)

    rebuy_price =
      D.sub(
        buy_price,
        D.mult(buy_price, rebuy_interval)
      )

    D.lt?(current_price, rebuy_price)
  end
end
