defmodule Naive.TraderTest do
  use ExUnit.Case

  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  @tag :unit
  test "Placing buy order test" do
    Test.PubSubMock
    |> expect(:subscribe, fn (_module, "TRADE_EVENTS:XRPUSDT") -> :ok end)
    |> expect(:broadcast, fn (_module, "ORDERS:XRPUSDT", _order) -> :ok end)

    Test.LoggerMock
    |> expect(:info, fn (_message) -> :ok end)

    Test.BinanceMock
    |> expect(:order_limit_buy, fn ("XRPUSDT", "464.360", "0.4307", "GTC") ->
      {:ok, BinanceMock.generate_fake_order(
        "12345",
        "XRPUSDT",
        "464.360",
        "0.4307",
        "BUY"
      )
      |> BinanceMock.convert_order_to_order_response()}
    end)

    test_pid = self()
    Test.Naive.LeaderMock
    |> expect(:notify, fn (:trader_state_updated, %Naive.Trader.State{}) ->
      send(test_pid, :ok)
      :ok
    end)

    trader_state = dummy_trader_state()
    trade_event = generate_event(1, "0.43183010", "213.10000000")

    {:ok, trader_pid} = Naive.Trader.start_link(trader_state)
    send(trader_pid, trade_event)
    assert_receive :ok
  end

  defp dummy_trader_state() do
    %Naive.Trader.State{
      id: 100_000_000,
      symbol: "XRPUSDT",
      budget: "200",
      buy_order: nil,
      sell_order: nil,
      buy_down_interval: Decimal.new("0.0025"),
      profit_interval: Decimal.new("0.001"),
      rebuy_interval: Decimal.new("0.006"),
      rebuy_notified: false,
      tick_size: "0.0001",
      step_size: "0.001"
    }
  end

  defp generate_event(id, price, quantity) do
    %Core.Struct.TradeEvent{
      event_type: "trade",
      event_time: 1_000 + id * 10,
      symbol: "XRPUSDT",
      trade_id: 2_000 + id * 10,
      price: price,
      quantity: quantity,
      buyer_order_id: 3_000 + id * 10,
      seller_order_id: 4_000 + id * 10,
      trade_time: 5_000 + id * 10,
      buyer_market_maker: false
    }
  end

end
