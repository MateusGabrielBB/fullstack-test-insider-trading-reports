defmodule InsiderTraderReporterService.Transaction do
  defstruct [
    transaction_data: %{
      transaction_date: "",
      transaction_shares_amount: 0,
      transaction_per_share_price: 0.0,
      transaction_value: 0.0,
      market_cap_percentage_value: "0.0%"
    }
  ]
end
