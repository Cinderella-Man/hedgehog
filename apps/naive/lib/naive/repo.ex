defmodule Naive.Repo do
  use Ecto.Repo,
    otp_app: :naive,
    adapter: Ecto.Adapters.Postgres
end
