defmodule DataWarehouse.Repo.Migrations.CreateSubscriberSettings do
  use Ecto.Migration

  alias DataWarehouse.Schema.SubscriberStatusEnum

  def change do
    SubscriberStatusEnum.create_type()

    create table(:subscriber_settings, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:topic, :text, null: false)
      add(:status, SubscriberStatusEnum.type(), default: "off", null: false)

      timestamps()
    end

    create(unique_index(:subscriber_settings, [:topic]))
  end
end
