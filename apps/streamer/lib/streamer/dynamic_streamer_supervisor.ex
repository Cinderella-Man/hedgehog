defmodule Streamer.DynamicStreamerSupervisor do
  use DynamicSupervisor

  require Logger

  import Ecto.Query, only: [from: 2]

  alias Streamer.Repo
  alias Streamer.Schema.Settings

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def autostart_streaming() do
    fetch_symbols_to_stream()
    |> Enum.map(&start_streaming/1)
  end

  def start_streaming(symbol) when is_binary(symbol) do
    symbol = String.upcase(symbol)

    case get_pid(symbol) do
      nil ->
        Logger.info("Starting streaming on #{symbol}")
        {:ok, _settings} = update_streaming_status(symbol, "on")
        {:ok, _pid} = start_streamer(symbol)

      pid ->
        Logger.warn("Streaming on #{symbol} already started")
        {:ok, _settings} = update_streaming_status(symbol, "on")
        {:ok, pid}
    end
  end

  def stop_streaming(symbol) when is_binary(symbol) do
    symbol = String.upcase(symbol)

    case get_pid(symbol) do
      nil ->
        Logger.warn("Streaming on #{symbol} already stopped")
        {:ok, _settings} = update_streaming_status(symbol, "off")

      pid ->
        Logger.info("Stopping streaming on #{symbol}")

        :ok =
          DynamicSupervisor.terminate_child(
            Streamer.DynamicStreamerSupervisor,
            pid
          )

        {:ok, _settings} = update_streaming_status(symbol, "off")
    end
  end

  defp get_pid(symbol) do
    Process.whereis(:"Elixir.Streamer.Binance-#{symbol}")
  end

  defp update_streaming_status(symbol, status)
       when is_binary(symbol) and is_binary(status) do
    Repo.get_by(Settings, symbol: symbol)
    |> Ecto.Changeset.change(%{status: status})
    |> Repo.update()
  end

  defp start_streamer(symbol) do
    DynamicSupervisor.start_child(
      Streamer.DynamicStreamerSupervisor,
      {Streamer.Binance, symbol}
    )
  end

  defp fetch_symbols_to_stream() do
    Repo.all(
      from(s in Settings,
        where: s.status == "on",
        select: s.symbol
      )
    )
  end
end
