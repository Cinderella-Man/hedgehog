defmodule Naive.DynamicSymbolSupervisor do
  use DynamicSupervisor

  require Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(
      __MODULE__,
      init_arg,
      name: __MODULE__
    )
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def autostart_symbols() do
    Core.ServiceSupervisor.autostart_workers(
      Naive.Repo,
      Naive.Schema.Settings
    )
  end

  def start_trading(symbol) when is_binary(symbol) do
    Core.ServiceSupervisor.start_worker(
      symbol,
      Naive.Repo,
      Naive.Schema.Settings
    )
  end

  def stop_trading(symbol) when is_binary(symbol) do
    Core.ServiceSupervisor.stop_worker(
      symbol,
      Naive.Repo,
      Naive.Schema.Settings
    )
  end

  def shutdown_trading(symbol) when is_binary(symbol) do
    symbol = String.upcase(symbol)

    case Core.ServiceSupervisor.get_pid(symbol) do
      nil ->
        Logger.warn("Trading on #{symbol} already stopped")

        {:ok, _settings} =
          Core.ServiceSupervisor.update_status(symbol, "off", Naive.Repo, Naive.Schema.Settings)

      _pid ->
        Logger.info("Shutdown of trading on #{symbol} initialized")

        {:ok, settings} =
          Core.ServiceSupervisor.update_status(
            symbol,
            "shutdown",
            Naive.Repo,
            Naive.Schema.Settings
          )

        Naive.Leader.notify(:settings_updated, settings)
        {:ok, settings}
    end
  end
end
