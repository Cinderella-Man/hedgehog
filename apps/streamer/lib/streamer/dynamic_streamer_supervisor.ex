defmodule Streamer.DynamicStreamerSupervisor do
  use DynamicSupervisor

  require Logger

  alias Streamer.Repo
  alias Streamer.Schema.Settings
  alias Streamer.Binance

  import Ecto.Query, only: [from: 2]

  @registry :binance_workers

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
    Logger.info("Starting streaming #{symbol} trade events")
    update_status(symbol, "on")
    start_child(symbol)
  end

  def stop_worker(symbol) do
    Logger.info("Stopping streaming #{symbol} trade events")
    update_status(symbol, "off")
    stop_child(symbol)
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
      {Binance, args}
    )
  end

  defp stop_child(args) do
    case Registry.lookup(@registry, args) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      _ -> Logger.warn("Unable to locate process assigned to #{inspect(args)}")
    end
  end
end
