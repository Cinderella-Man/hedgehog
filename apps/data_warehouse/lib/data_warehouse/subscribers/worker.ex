defmodule DataWarehouse.Subscribers.Worker do
  use GenServer, restart: :temporary

  require Logger

  defmodule State do
    @enforce_keys [:stream_name, :symbol]
    defstruct [:stream_name, :symbol]
  end

  def start_link(%{stream_name: stream_name, symbol: symbol} = args) do
    GenServer.start_link(
      __MODULE__,
      args,
      name: :"#{__MODULE__}-#{stream_name}-#{symbol}"
    )
  end

  def init(%{stream_name: stream_name, symbol: symbol}) do
    topic = "#{stream_name}:#{symbol}"
    Logger.info("DataWarehouse worker is subscribing to #{topic}")

    Phoenix.PubSub.subscribe(
      Streamer.PubSub,
      topic
    )

    {:ok,
     %State{
       stream_name: stream_name,
       symbol: symbol
     }}
  end

  def handle_info(
        %Streamer.Binance.TradeEvent{} = trade_event,
        state
      ) do
    opts =
      trade_event
      |> Map.to_list()
      |> Keyword.delete(:__struct__)

    struct!(DataWarehouse.TradeEvent, opts)
    |> DataWarehouse.Repo.insert()

    {:noreply, state}
  end

  def handle_info(
        %Binance.Order{} = order,
        state
      ) do
    %DataWarehouse.Order{
      symbol: order.symbol,
      order_id: order.order_id,
      client_order_id: order.client_order_id,
      price: order.price,
      original_quantity: order.orig_qty,
      executed_quantity: order.executed_qty,
      cummulative_quote_quantity: order.cummulative_quote_qty,
      status: order.status,
      time_in_force: order.time_in_force,
      type: order.type,
      side: order.side,
      stop_price: order.stop_price,
      iceberg_quantity: order.iceberg_qty,
      time: order.time,
      update_time: order.update_time
    }
    |> DataWarehouse.Repo.insert(
      on_conflict: :replace_all,
      conflict_target: :order_id
    )

    {:noreply, state}
  end
end
