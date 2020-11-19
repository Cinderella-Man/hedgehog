defmodule Naive.Schema.Settings do
  use Ecto.Schema

  alias Naive.Schema.TradingStatusEnum

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "settings" do
    field(:symbol, :string)
    field(:chunks, :integer)
    field(:budget, :decimal)
    field(:buy_down_interval, :decimal)
    field(:profit_interval, :decimal)
    field(:rebuy_interval, :decimal)
    field(:status, TradingStatusEnum)

    timestamps()
  end
end
