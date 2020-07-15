defmodule Naive.Trader do
  use GenServer, restart: :temporary

  require Logger
  alias Decimal, as: D

  defmodule State do
    @enforce_keys [:symbol, :profit_interval, :tick_size]
    defstruct [
      :symbol,
      :buy_order,
      :sell_order,
      :profit_interval,
      :tick_size
    ]
  end

  def start_link(%State{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(%State{} = state) do
    {:ok, state}
  end

  def handle_cast(
    {:event,
    %Streamer.Binance.TradeEvent{
      price: price
    }},
    %State{
      symbol: symbol,
      buy_order: nil
    } = state
  ) do
    Logger.info(
      "Placing buy order (#{symbol}@#{price})"
    )

    quantity = 100

    {:ok, %Binance.OrderResponse{} = order} =
      Binance.order_limit_buy(
        symbol,
        quantity,
        price,
        "GTC"
      )

    new_state = %{state | buy_order: order}
    Naive.Leader.notify(:trader_state_updated, new_state)
    {:noreply, new_state}
  end

  def handle_cast(
    {:event,
    %Streamer.Binance.TradeEvent{
      buyer_order_id: order_id,
      quantity: quantity
    }},
    %State{
      symbol: symbol,
      buy_order: %Binance.OrderResponse{
        price: buy_price,
        order_id: order_id,
        orig_qty: quantity
      },
      profit_interval: profit_interval,
      tick_size: tick_size
    } = state
  ) do
    sell_price = calculate_sell_price(
      buy_price,
      profit_interval,
      tick_size
    )

    Logger.info(
      "Buy order filled, placing sell order (#{symbol}@#{sell_price})"
    )

    {:ok, %Binance.OrderResponse{} = order} =
      Binance.order_limit_sell(
        symbol,
        quantity,
        sell_price,
        "GTC"
      )
    new_state = %{state | sell_order: order}
    Naive.Leader.notify(:trader_state_updated, new_state)
    {:noreply, new_state}
  end

  def handle_cast(
    {:event,
    %Streamer.Binance.TradeEvent{
      seller_order_id: order_id,
      quantity: quantity
    }},
    %State{
      sell_order: %Binance.OrderResponse{
        order_id: order_id,
        orig_qty: quantity
      }
    } = state
  ) do
    Logger.info(
      "Trade finished, trader will now exit"
    )

    {:stop, :trade_finished, state}
  end

  def handle_cast(
    {:event, _},
    state
  ) do
    {:noreply, state}
  end

  defp calculate_sell_price(
    buy_price,
    profit_interval,
    tick_size
  ) do
    fee = D.cast("1.001")
    original_price = D.mult(D.cast(buy_price), fee)
    tick = D.cast(tick_size)

    net_target_price = D.mult(
      original_price,
      D.add("1.0", D.cast(profit_interval))
    )

    gross_target_price = D.mult(
      net_target_price,
      fee
    )

    D.to_float(
      D.mult(
        D.div_int(gross_target_price, tick),
        tick
      )
    )
  end
end