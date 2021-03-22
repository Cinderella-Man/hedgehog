defmodule Naive.DynamicSymbolSupervisor do
  use Core.ServiceSupervisor,
    repo: Naive.Repo,
    schema: Naive.Schema.Settings,
    module: __MODULE__,
    worker_module: Naive.SymbolSupervisor

  require Logger

  def start_link(init_arg) do
    Core.ServiceSupervisor.start_link(
      __MODULE__,
      init_arg,
      name: __MODULE__
    )
  end

  def init(_init_arg) do
    Core.ServiceSupervisor.init(strategy: :one_for_one)
  end

  def shutdown_trading(symbol) when is_binary(symbol) do
    symbol = String.upcase(symbol)

    case get_pid(symbol) do
      nil ->
        Logger.warn("Trading on #{symbol} already stopped")

        {:ok, _settings} = update_status(symbol, "off")

      _pid ->
        Logger.info("Shutdown of trading on #{symbol} initialized")

        {:ok, settings} = update_status(symbol, "shutdown")

        Naive.Leader.notify(:settings_updated, settings)
        {:ok, settings}
    end
  end
end
