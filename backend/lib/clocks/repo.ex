defmodule Clocks.Repo do
  use Ecto.Repo,
    otp_app: :clocks,
    adapter: Ecto.Adapters.Postgres
end
