defmodule DataWarehouse.Schema.Order do
  use Ecto.Schema

  @primary_key {:order_id, :integer, autogenerate: false}

  schema "orders" do
    field(:client_order_id, :string)
    field(:symbol, :string)
    field(:price, :string)
    field(:original_quantity, :string)
    field(:executed_quantity, :string)
    field(:cummulative_quote_quantity, :string)
    field(:status, :string)
    field(:time_in_force, :string)
    field(:type, :string)
    field(:side, :string)
    field(:stop_price, :string)
    field(:iceberg_quantity, :string)
    field(:time, :integer)
    field(:update_time, :integer)

    timestamps()
  end
end
