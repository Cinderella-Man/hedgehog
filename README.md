# Hedgehog

Repository created to follow along the [Create a cryptocurrency trading bot in Elixir](https://www.youtube.com/playlist?list=PLxsE19GnjC5Nv1CbeKOiS5YqGqw35aZFJ) course.

Each subsequent video has assigned git branch that stores a state of the code after it.

## Setup

Insert `api_key` and `secret_key` inside `config/config.exs` file and run `mix deps.get` 

## Running

```
iex -S mix

# connect to the Binance and stream into PubSub
Streamer.start_streaming("xrpusdt")

# to store trade_events in db
DataWarehouse.Subscribers.Server.start_storing("trade_events", "xrpusdt")

# to store orders in db
DataWarehouse.Subscribers.Server.start_storing("orders", "xrpusdt")

# turn on naive strategy
Naive.Server.start_trading("XRPUSDT")
```

## Postgres cheat sheet

```
psql -U postgres -h 127.0.0.1
Password for user postgres: postgres
...
postgres=# \c data_warehouse
...
postgres=# \x
...
data_warehouse=# SELECT COUNT(*) FROM trade_events;
...
data_warehouse=# SELECT COUNT(*) FROM orders;
```

## Loading backtesting data

```
cd /tmp

wget https://github.com/Cinderella-Man/binance-trade-events/raw/master/XRPUSDT/XRPUSDT-2019-06-03.csv.gz

gunzip XRPUSDT-2019-06-03.csv.gz

PGPASSWORD=postgres psql -Upostgres -h localhost -ddata_warehouse  -c "\COPY trade_events FROM '/tmp/XRPUSDT-2019-06-03.csv' WITH (FORMAT csv, delimiter ';');"

```

## Running backtesting

```
DataWarehouse.Subscribers.Server.start_storing("orders", "xrpusdt")

Naive.Server.start_trading("XRPUSDT")

DataWarehouse.Publisher.start_link(%{
  type: :trade_events,
  symbol: "XRPUSDT",
  from: "2019-06-02",
  to: "2019-06-04",
  interval: 5
})
```