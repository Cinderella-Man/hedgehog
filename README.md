# Hedgehog

Repository created to follow along with the [Create a cryptocurrency trading bot in Elixir](https://www.youtube.com/playlist?list=PLxsE19GnjC5Nv1CbeKOiS5YqGqw35aZFJ) course.

Each subsequent video has an assigned git branch that stores a state of the code after it.

For anyone interested in an ebook version of the course, I've published one at [LeanPub](https://leanpub.com/create-a-cryptocurrency-trading-bot-in-elixir).

## Limit of Liability/Disclaimer of Warranty

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


## Intial setup

1. Install the required dependencies:

```
$ mix deps.get
...
```

2. Start Postgres instance inside docker:

```
$ docker-compose up -d
Creating hedgehog_db_1 ... done
```

3. Create databases inside the Postgres instance:

```
$ mix ecto.create
The database for DataWarehouse.Repo has been created
The database for Naive.Repo has been created
The database for Streamer.Repo has been created
```

4. Migrate all databases:

```
$ mix ecto.migrate
...
```

5. Seed default settings into the `naive` database:

```
$ cd apps/naive
$ mix run priv/seed_settings.exs
...
```

6. Seed default settings into the `streamer` database:

```
$ cd apps/streamer
$ mix run priv/seed_settings.exs
...
```

## Further setup (danger zone)

Inside the configuration file(`config/config.exs`) there's a setting(`config :naive, binance_client`) specifying which Binance client should be used. By default, it's the `BinanceMock` module that *won't* connect to the Binance exchange at all neither it will require any access configuration as it stores orders in memory.

To connect to the Binance exchange and make real trades the configuration needs to be changed to the `Binance` client:

```
# /config/config.exs:L22
binance_client: BinanceMock, => binance_client: Binance,
```
as well as `api_key` and `secret_key` need to be set:

```
# /config/config.exs:L49
config :binance,
  api_key: "insert value here",
  secret_key: "insert value here"
```

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
Naive.start_trading("XRPUSDT")
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