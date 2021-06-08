defmodule DataWarehouse.Subscriber.Worker do
  use GenServer

  require Logger

  defmodule State do
    @enforce_keys [:topic]
    defstruct [:topic]
  end

  def start_link(topic) do
    GenServer.start_link(
      __MODULE__,
      topic,
      name: via_tuple(topic)
    )
  end

  def init(topic) do
    Logger.info("DataWarehouse worker is subscribing to #{topic}")

    Phoenix.PubSub.subscribe(
      Streamer.PubSub,
      topic
    )

    {:ok,
     %State{
       topic: topic
     }}
  end

  def handle_info(
        %Core.Struct.TradeEvent{} = trade_event,
        state
      ) do
    opts =
      trade_event
      |> Map.to_list()
      |> Keyword.delete(:__struct__)

    struct!(DataWarehouse.Schema.TradeEvent, opts)
    |> DataWarehouse.Repo.insert()

    {:noreply, state}
  end

  def handle_info(
        %Binance.Order{} = order,
        state
      ) do
    %DataWarehouse.Schema.Order{
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

  defp via_tuple(topic) do
    {:via, Registry, {:subscriber_workers, topic}}
  end
end
