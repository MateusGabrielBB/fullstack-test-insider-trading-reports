defmodule InsiderTraderReporterService.Repo do
  use Ecto.Repo,
    otp_app: :insider_trader_reporter_service,
    adapter: Ecto.Adapters.Postgres
end
