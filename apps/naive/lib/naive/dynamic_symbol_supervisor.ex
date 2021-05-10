defmodule Naive.DynamicSymbolSupervisor do
  use DynamicSupervisor

  require Logger

  alias Naive.Repo
  alias Naive.Schema.Settings
  alias Naive.SymbolSupervisor

  import Ecto.Query, only: [from: 2]

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def autostart_workers() do
    Repo.all(
      from(s in Settings,
        where: s.enabled == true,
        select: s.symbol
      )
    )
    |> Enum.map(&start_child/1)
  end

  def start_worker(symbol) do
    Logger.info("Starting trading on #{symbol}")
    update_enabled(symbol, true)
    start_child(symbol)
  end

  def stop_worker(symbol) do
    Logger.info("Stopping trading on #{symbol}")
    update_enabled(symbol, false)
    stop_child(symbol)
  end

  defp update_enabled(symbol, value)
      when is_binary(symbol) and is_boolean(value) do
    Repo.get_by(Settings, symbol: symbol)
    |> Ecto.Changeset.change(%{enabled: value})
    |> Repo.update()
  end

  defp start_child(args) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {SymbolSupervisor, args}
    )
  end

  defp stop_child(args) do
    case Registry.lookup(:naive_symbol_supervisors, args) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      _ -> Logger.warn("Unable to locate process assigned to #{inspect(args)}")
    end
  end
end
