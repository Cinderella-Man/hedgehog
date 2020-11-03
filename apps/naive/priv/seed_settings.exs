require Logger

alias Decimal
alias Naive.Repo
alias Naive.Schema.Settings

binance_client = Application.get_env(:naive, :binance_client)

Logger.info("Fetching exchange info from Binance to create trading settings")

{:ok, %{symbols: symbols}} = binance_client.get_exchange_info()

Logger.info("Inserting default settings for symbols")

%{
  chunks: chunks,
  budget: budget,
  buy_down_interval: buy_down_interval,
  profit_interval: profit_interval,
  rebuy_interval: rebuy_interval
} = Application.get_env(:naive, :trading).defaults

timestamp = NaiveDateTime.utc_now()
  |> NaiveDateTime.truncate(:second)

base_settings = %{
  symbol: "",
  chunks: chunks,
  budget: Decimal.from_float(budget),
  buy_down_interval: Decimal.from_float(buy_down_interval),
  profit_interval: Decimal.from_float(profit_interval),
  rebuy_interval: Decimal.from_float(rebuy_interval),
  status: "off",
  inserted_at: timestamp,
  updated_at: timestamp
}

maps = symbols
  |> Enum.map(&(%{base_settings | symbol: &1["symbol"]}))

{count, nil} = Repo.insert_all(Settings, maps)

Logger.info("Inserted settings for #{count} symbols")