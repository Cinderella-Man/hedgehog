defmodule DataWarehouse.Worker do
  use GenServer

  require Logger

  defmodule State do
    @enforce_keys [:stream, :symbol]
    defstruct [:stream, :symbol]
  end

  def start_link(%{stream: stream, symbol: symbol} = args) do
    GenServer.start_link(
      __MODULE__,
      args,
      name: :"#{__MODULE__}-#{stream}-#{symbol}"
    )
  end

  def init(%{stream: stream, symbol: symbol}) do
    symbol = String.downcase(symbol)
    Logger.info("DataWarehouse worker subscribing on #{symbol}")

    Phoenix.PubSub.subscribe(
      Streamer.PubSub,
      "#{stream}:#{symbol}"
    )

    {:ok, %State{
      stream: stream,
      symbol: symbol
    }}
  end

  def handle_info(
    %Streamer.Binance.TradeEvent{} = trade_event,
    state
  ) do
    opts = trade_event
    |> Map.to_list()
    |> Keyword.delete(:__struct__)

    struct!(DataWarehouse.TradeEvent, opts)
    |> DataWarehouse.Repo.insert()

    {:noreply, state}
  end
end