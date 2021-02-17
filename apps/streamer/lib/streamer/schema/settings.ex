defmodule Streamer.Schema.Settings do
  use Ecto.Schema

  alias Streamer.Schema.StreamingStatusEnum

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "settings" do
    field(:symbol, :string)
    field(:status, StreamingStatusEnum)

    timestamps()
  end
end
