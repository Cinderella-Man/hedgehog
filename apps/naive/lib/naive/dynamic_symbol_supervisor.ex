defmodule Naive.DynamicSymbolSupervisor do
  use DynamicSupervisor

  require Logger

  alias Naive.Repo
  alias Naive.Schema.Settings
  alias Naive.SymbolSupervisor

  import Ecto.Query, only: [from: 2]

  @registry :naive_symbol_supervisors

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def autostart_workers() do
    Repo.all(
      from(s in Settings,
        where: s.status == "on",
        select: s.symbol
      )
    )
    |> Enum.map(&start_child/1)
  end

  def start_worker(symbol) do
    Logger.info("Starting trading on #{symbol}")
    update_status(symbol, "on")
    start_child(symbol)
  end

  def stop_worker(symbol) do
    Logger.info("Stopping trading on #{symbol}")
    update_status(symbol, "off")
    stop_child(symbol)
  end

  def shutdown_trading(symbol) when is_binary(symbol) do
    Logger.info("Shutdown of trading on #{symbol} initialized")
    {:ok, settings} = update_status(symbol, "shutdown")
    Naive.Leader.notify(:settings_updated, settings)
    {:ok, settings}
  end

  defp update_status(symbol, status)
       when is_binary(symbol) and is_binary(status) do
    Repo.get_by(Settings, symbol: symbol)
    |> Ecto.Changeset.change(%{status: status})
    |> Repo.update()
  end

  defp start_child(args) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {SymbolSupervisor, args}
    )
  end

  defp stop_child(args) do
    case Registry.lookup(@registry, args) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      _ -> Logger.warn("Unable to locate process assigned to #{inspect(args)}")
    end
  end
end
