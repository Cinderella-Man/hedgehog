defmodule Naive.SymbolSupervisor do
  use Supervisor

  require Logger

  def start_link(symbol) do
    Supervisor.start_link(
      __MODULE__,
      symbol,
      name: via_tuple(symbol)
    )
  end

  def init(symbol) do
    Logger.info("Naive strategy is starting trading on #{symbol}")

    Supervisor.init(
      [
        {
          DynamicSupervisor,
          strategy: :one_for_one,
          name: :"Naive.DynamicTraderSupervisor-#{symbol}"
        },
        {Naive.Leader, symbol}
      ],
      strategy: :one_for_all
    )
  end

  defp via_tuple(symbol) do
    {:via, Registry, {:naive_symbol_supervisors, symbol}}
  end
end
