defmodule Core.ServiceSupervisor do
  require Logger

  import Ecto.Query, only: [from: 2]

  defdelegate start_link(module, args, opts), to: DynamicSupervisor
  defdelegate init(opts), to: DynamicSupervisor

  defmacro __using__(opts) do
    {:ok, repo} = Keyword.fetch(opts, :repo)
    {:ok, schema} = Keyword.fetch(opts, :schema)
    {:ok, module} = Keyword.fetch(opts, :module)
    {:ok, worker_module} = Keyword.fetch(opts, :worker_module)
    quote location: :keep do
      use DynamicSupervisor

      def autostart_workers() do
        Core.ServiceSupervisor.autostart_workers(
          unquote(repo),
          unquote(schema),
          unquote(module),
          unquote(worker_module)
        )
      end

      def start_worker(symbol) when is_binary(symbol) do
        Core.ServiceSupervisor.start_worker(
          symbol,
          unquote(repo),
          unquote(schema),
          unquote(module),
          unquote(worker_module)
        )
      end

      def stop_worker(symbol) when is_binary(symbol) do
        Core.ServiceSupervisor.stop_worker(
          symbol,
          unquote(repo),
          unquote(schema),
          unquote(module),
          unquote(worker_module)
        )
      end

      def get_pid(symbol) do
        Core.ServiceSupervisor.get_pid(
          unquote(worker_module),
          symbol
        )
      end

      def update_status(symbol, status) do
        Core.ServiceSupervisor.update_status(
          symbol,
          status,
          unquote(repo),
          unquote(schema)
        )
      end
    end
  end

  def autostart_workers(repo, schema, module, worker_module) do
    fetch_symbols_to_start(repo, schema)
    |> Enum.map(&start_worker(&1, repo, schema, module, worker_module))
  end

  def start_worker(symbol, repo, schema, module, worker_module) when is_binary(symbol) do
    symbol = String.upcase(symbol)

    case get_pid(worker_module, symbol) do
      nil ->
        Logger.info("Starting worker on #{symbol}")
        {:ok, _settings} = update_status(symbol, "on", repo, schema)

        {:ok, _pid} =
          DynamicSupervisor.start_child(
            module,
            {worker_module, symbol}
          )

      pid ->
        Logger.warn("worker on #{symbol} already started")
        {:ok, _settings} = update_status(symbol, "on", repo, schema)
        {:ok, pid}
    end
  end

  def stop_worker(symbol, repo, schema, module, worker_module) when is_binary(symbol) do
    symbol = String.upcase(symbol)

    case get_pid(worker_module, symbol) do
      nil ->
        Logger.warn("worker on #{symbol} already stopped")
        {:ok, _settings} = update_status(symbol, "off", repo, schema)

      pid ->
        Logger.info("Stopping worker on #{symbol}")

        :ok =
          DynamicSupervisor.terminate_child(
            module,
            pid
          )

        {:ok, _settings} = update_status(symbol, "off", repo, schema)
    end
  end

  def get_pid(worker_module, symbol) do
    Process.whereis(:"#{worker_module}-#{symbol}")
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
