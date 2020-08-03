defmodule Naive.Trader do
  use GenServer, restart: :temporary

  require Logger
  alias Decimal, as: D

  defmodule State do
    @enforce_keys [
      :symbol,
      :budget,
      :buy_down_interval,
      :profit_interval,
      :tick_size,
      :step_size
    ]
    defstruct [
      :symbol,
      :budget,
      :buy_order,
      :sell_order,
      :buy_down_interval,
      :profit_interval,
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
      "trade:#{state.symbol}"
    )

    {:ok, state}
  end

  def handle_info(
        %Streamer.Binance.TradeEvent{
          price: price
        },
        %State{
          symbol: symbol,
          budget: budget,
          buy_order: nil,
          buy_down_interval: buy_down_interval,
          tick_size: tick_size,
          step_size: step_size
        } = state
      ) do
    buy_price = calculate_buy_price(
      price,
      buy_down_interval,
      tick_size
    )

    Logger.info("Placing buy order (#{symbol}@#{buy_price})")

    quantity = calculate_quantity(
      budget,
      buy_price,
      step_size
    )

    {:ok, %Binance.OrderResponse{} = order} =
      Binance.order_limit_buy(
        symbol,
        quantity,
        buy_price,
        "GTC"
      )

    new_state = %{state | buy_order: order}
    Naive.Leader.notify(:trader_state_updated, new_state)
    {:noreply, new_state}
  end

  def handle_info(
        %Streamer.Binance.TradeEvent{
          buyer_order_id: order_id,
          quantity: quantity
        },
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
    sell_price =
      calculate_sell_price(
        buy_price,
        profit_interval,
        tick_size
      )

    Logger.info("Buy order filled, placing sell order (#{symbol}@#{sell_price})")

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

  def handle_info(
        %Streamer.Binance.TradeEvent{
          seller_order_id: order_id,
          quantity: quantity
        },
        %State{
          sell_order: %Binance.OrderResponse{
            order_id: order_id,
            orig_qty: quantity
          }
        } = state
      ) do
    Logger.info("Trade finished, trader will now exit")

    {:stop, :trade_finished, state}
  end

  def handle_info(
        _,
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

    net_target_price =
      D.mult(
        original_price,
        D.add("1.0", D.cast(profit_interval))
      )

    gross_target_price =
      D.mult(
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

  defp calculate_buy_price(
    price,
    buy_down_interval,
    tick_size
  ) do
    current_price = D.cast(price)
    interval = D.cast(buy_down_interval)
    tick = D.cast(tick_size)

    # not necessarily legal price
    exact_buy_price = D.sub(
      current_price,
      D.mult(current_price, interval)
    )

    D.to_float(
      D.mult(
        D.div_int(exact_buy_price, tick),
        tick
      )
    )
  end

  defp calculate_quantity(
    budget,
    price,
    step_size
  ) do
    step = D.cast(step_size)
    price = D.cast(price)

    # not necessarily legal quantity
    exact_target_quantity = D.div(budget, price)

    D.to_float(
      D.mult(
        D.div_int(exact_target_quantity, step),
        step
      )
    )
  end
end
