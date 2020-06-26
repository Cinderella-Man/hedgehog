# Hedgehog

Repository created to follow along the [Create a cryptocurrency trading bot in Elixir](https://www.youtube.com/playlist?list=PLxsE19GnjC5Nv1CbeKOiS5YqGqw35aZFJ) course.

Each subsequent video has assigned git branch that stores a state of the code after it.

## Setup

Insert `api_key` and `secret_key` inside `config/config.exs` file and run `mix deps.get` 

## Running

```
iex -S mix

Naive.Trader.start_link(%{symbol: "XRPUSDT", profit_interval: 0.01})

Streamer.Binance.start_link("xrpusdt", [])
```