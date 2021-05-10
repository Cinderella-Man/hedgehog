defmodule Streamer.Schema.Settings do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "settings" do
    field(:symbol, :string)

    timestamps()
  end
end
