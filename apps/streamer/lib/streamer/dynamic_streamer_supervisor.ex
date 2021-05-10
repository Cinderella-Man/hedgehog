defmodule Streamer.DynamicStreamerSupervisor do
  use DynamicSupervisor

  require Logger

  alias Streamer.Repo
  alias Streamer.Schema.Settings

  import Ecto.Query, only: [from: 2]

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def autostart_workers() do
    Settings
    |> Repo.all()
    |> Enum.map(&start_child(&1.symbol))
  end

  def start_worker(symbol) do
    Logger.info("Starting streaming #{symbol} trade events")
    {:ok, _settings} = upsert_symbol_settings(symbol)
    start_child(symbol)
  end

  def stop_worker(symbol) do
    Logger.info("Stopping streaming #{symbol} trade events")
    delete_symbol_settings(symbol)
    stop_child(symbol)
  end

  defp start_child(args) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Streamer.Binance, args}
    )
  end

  defp stop_child(args) do
    case Registry.lookup(:binance_workers, args) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      _ -> Logger.warn("Unable to locate process assigned to #{inspect(args)}")
    end
  end

  defp upsert_symbol_settings(symbol) do
    %Settings{symbol: symbol}
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: :symbol
    )
  end

  defp delete_symbol_settings(symbol) do
    from(s in Settings, where: s.symbol == ^symbol)
    |> Repo.delete_all()
  end
end
