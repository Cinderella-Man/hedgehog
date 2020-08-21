defmodule Streamer do
  @moduledoc """
  Documentation for `Streamer`.
  """

  def start_streaming(symbol) do
    Streamer.Binance.start_link(symbol)
  end
end
