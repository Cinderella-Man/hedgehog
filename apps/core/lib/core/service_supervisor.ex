defmodule Core.ServiceSupervisor do
  require Logger

  import Ecto.Query, only: [from: 2]

  def autostart_workers(repo, schema) do
    fetch_symbols_to_start(repo, schema)
    |> Enum.map(&start_worker(&1, repo, schema))
  end

  def start_worker(symbol, repo, schema) when is_binary(symbol) do
    symbol = String.upcase(symbol)

    case get_pid(symbol) do
      nil ->
        Logger.info("Starting worker on #{symbol}")
        {:ok, _settings} = update_status(symbol, "on", repo, schema)

        {:ok, _pid} =
          DynamicSupervisor.start_child(
            Naive.DynamicSymbolSupervisor,
            {Naive.SymbolSupervisor, symbol}
          )

      pid ->
        Logger.warn("worker on #{symbol} already started")
        {:ok, settings} = update_status(symbol, "on", repo, schema)
        Naive.Leader.notify(:settings_updated, settings)
        {:ok, pid}
    end
  end

  def stop_worker(symbol, repo, schema) when is_binary(symbol) do
    symbol = String.upcase(symbol)

    case get_pid(symbol) do
      nil ->
        Logger.warn("worker on #{symbol} already stopped")
        {:ok, _settings} = update_status(symbol, "off", repo, schema)

      pid ->
        Logger.info("Stopping worker on #{symbol}")

        :ok =
          DynamicSupervisor.terminate_child(
            Naive.DynamicSymbolSupervisor,
            pid
          )

        {:ok, _settings} = update_status(symbol, "off", repo, schema)
    end
  end

  def get_pid(symbol) do
    Process.whereis(:"Elixir.Naive.SymbolSupervisor-#{symbol}")
  end

  def update_status(symbol, status, repo, schema)
      when is_binary(symbol) and is_binary(status) do
    repo.get_by(schema, symbol: symbol)
    |> Ecto.Changeset.change(%{status: status})
    |> repo.update()
  end

  defp fetch_symbols_to_start(repo, schema) do
    repo.all(
      from(s in schema,
        where: s.status == "on",
        select: s.symbol
      )
    )
  end
end
