defmodule Streamer.Repo do
  use Ecto.Repo,
    otp_app: :streamer,
    adapter: Ecto.Adapters.Postgres
end
