defmodule DataWarehouse.Repo.Migrations.CreateTradeEvents do
  use Ecto.Migration

  def change do
    create table(:trade_events, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:event_type, :text)
      add(:event_time, :bigint)
      add(:symbol, :text)
      add(:trade_id, :integer)
      add(:price, :text)
      add(:quantity, :text)
      add(:buyer_order_id, :bigint)
      add(:seller_order_id, :bigint)
      add(:trade_time, :bigint)
      add(:buyer_market_maker, :bool)

      timestamps()
    end
  end
end
