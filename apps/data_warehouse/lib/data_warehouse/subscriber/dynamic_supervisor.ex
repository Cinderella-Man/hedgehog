defmodule DataWarehouse.Subscriber.DynamicSupervisor do
  use DynamicSupervisor

  require Logger

  alias DataWarehouse.Repo
  alias DataWarehouse.Schema.SubscriberSettings
  alias DataWarehouse.Subscriber.Worker

  import Ecto.Query, only: [from: 2]

  @registry :subscriber_workers

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def autostart_workers() do
    Repo.all(
      from(s in SubscriberSettings,
        where: s.status == "on",
        select: s.topic
      )
    )
    |> Enum.map(&start_child/1)
  end

  def start_worker(topic) do
    Logger.info("Starting storing data from #{topic} topic")
    update_status(topic, "on")
    start_child(topic)
  end

  def stop_worker(topic) do
    Logger.info("Stopping storing data from #{topic} topic")
    update_status(topic, "off")
    stop_child(topic)
  end

  defp update_status(topic, status)
       when is_binary(topic) and is_binary(status) do
    %SubscriberSettings{
      topic: topic,
      status: status
    }
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: :topic
    )
  end

  defp start_child(args) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Worker, args}
    )
  end

  defp stop_child(args) do
    case Registry.lookup(@registry, args) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      _ -> Logger.warn("Unable to locate process assigned to #{inspect(args)}")
    end
  end
end
