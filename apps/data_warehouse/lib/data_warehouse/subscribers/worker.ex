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

    {:ok, %State{
      stream_name: stream_name,
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