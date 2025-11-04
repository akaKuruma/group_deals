defmodule GroupDeals.Repo do
  use Ecto.Repo,
    otp_app: :group_deals,
    adapter: Ecto.Adapters.Postgres
end
