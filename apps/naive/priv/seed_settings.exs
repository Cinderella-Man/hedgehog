require Logger

alias Naive.Repo
alias Naive.Schema.Settings

Logger.info("Fetching exchange info from Binance to create trading settings")

{:ok, %{symbols: symbols}} = Binance.get_exchange_info()

timestamp = NaiveDateTime.utc_now()
  |> NaiveDateTime.truncate(:second)

base_settings = %{
  symbol: "",
  chunks: 5,
  budget: Decimal.new("100.0"),
  buy_down_interval: Decimal.new("0.001"),
  profit_interval: Decimal.new("0.001"),
  rebuy_interval: Decimal.new("0.05"),
  enabled: false,
  inserted_at: timestamp,
  updated_at: timestamp
}

Logger.info("Inserting default settings for symbols")

maps = symbols
  |> Enum.map(&(%{base_settings | symbol: &1["symbol"]}))

{count, nil} = Repo.insert_all(Settings, maps)

Logger.info("Inserted settings for #{count} symbols")