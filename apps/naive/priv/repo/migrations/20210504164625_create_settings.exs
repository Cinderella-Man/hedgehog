defmodule Naive.Repo.Migrations.CreateSettings do
  use Ecto.Migration

  def change do
    create table(:settings, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:symbol, :text, null: false)
      add(:chunks, :integer, null: false)
      add(:budget, :decimal, null: false)
      add(:buy_down_interval, :decimal, null: false)
      add(:profit_interval, :decimal, null: false)
      add(:rebuy_interval, :decimal, null: false)
      add(:enabled, :boolean, default: false, null: false)

      timestamps()
    end

    create(unique_index(:settings, [:symbol]))
  end
end
