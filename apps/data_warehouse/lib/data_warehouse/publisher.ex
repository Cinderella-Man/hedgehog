defmodule DataWarehouse.Publisher do
  use Task

  import Ecto.Query, only: [from: 2]

  require Logger

  def start_link(%{} = options) do
    Task.start_link(
      __MODULE__,
      :run,
      [options]
    )
  end

  def run(%{
    type: :trade_events,
    symbol: symbol,
    from: from,
    to: to,
    interval: interval
  }) do
    from_ts = "#{from}T00:00:00.000Z"
    |> convert_to_ms()

    to_ts = "#{to}T23:59:59.000Z"
    |> convert_to_ms()

    DataWarehouse.Repo.transaction(
      fn ->
        from(te in DataWarehouse.TradeEvent,
          where: te.symbol == ^symbol and
                 te.trade_time >= ^from_ts and
                 te.trade_time < ^to_ts,
          order_by: te.trade_time
        )
        |> DataWarehouse.Repo.stream()
        |> Enum.with_index()
        |> Enum.map(fn {row, index} ->
          :timer.sleep(interval)
          if (rem(index, 10_000) == 0) do
            Logger.info("Publisher broadcasted #{index} events")
          end
          publishTradeEvent(row)
        end)
      end,
      timeout: :infinity
    )

    Logger.info("Publisher finished streaming trade events")
  end

  defp publishTradeEvent(%DataWarehouse.TradeEvent{} = trade_event) do
    new_trade_event = struct(
      Streamer.Binance.TradeEvent,
      trade_event |> Map.to_list()
    )

    symbol = String.downcase(trade_event.symbol)
    Phoenix.PubSub.broadcast(
      Streamer.PubSub,
      "trade_events:#{symbol}",
      new_trade_event
    )
  end

  defp convert_to_ms(iso8601DateString) do
    iso8601DateString
    |> NaiveDateTime.from_iso8601!()
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_unix()
    |> Kernel.*(1000)
  end
end