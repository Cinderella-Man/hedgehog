defmodule Streamer.Repo.Migrations.CreateSettings do
  use Ecto.Migration

  alias Streamer.Schema.StreamingStatusEnum

  def change do
    StreamingStatusEnum.create_type()

    create table(:settings, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:symbol, :text, null: false)
      add(:status, StreamingStatusEnum.type(), default: "off", null: false)

      timestamps()
    end

    create(unique_index(:settings, [:symbol]))
  end
end
