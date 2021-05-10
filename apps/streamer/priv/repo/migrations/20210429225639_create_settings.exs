defmodule Streamer.Repo.Migrations.CreateSettings do
  use Ecto.Migration

  def change do
    create table(:settings, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:symbol, :text, null: false)

      timestamps()
    end

    create(unique_index(:settings, [:symbol]))
  end
end
