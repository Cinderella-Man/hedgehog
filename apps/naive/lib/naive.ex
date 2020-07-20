defmodule Naive do
  @moduledoc """
  Documentation for `Naive`.
  """
  def send_event(%Streamer.Binance.TradeEvent{} = event) do
    GenServer.cast(:trader, {:event, event})
  end
end
