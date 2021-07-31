defmodule BinanceMockBehaviour do

  alias Binance.OrderResponse

  @type symbol :: binary
  @type quantity :: binary
  @type price :: binary
  @type time_in_force :: binary

  @callback order_limit_buy(
    symbol,
    quantity,
    price,
    time_in_force
  ) :: {:ok, %OrderResponse{}} | {:error, term}

end
