defmodule InsiderTraderReporterService.Transaction do
  defstruct [
    transaction_date: "",
    transaction_shares_amount: 0,
    transaction_per_share_price: 0.0,
    transaction_value: 0.0,
    market_cap_percentage_value: "0.0%"
  ]

  def new(
        transaction_date,
        transaction_shares_amount,
        transaction_per_share_price,
        transaction_value,
        market_cap_percentage_value
      ) do
    %InsiderTraderReporterService.Transaction{
      transaction_date: transaction_date,
      transaction_shares_amount: transaction_shares_amount,
      transaction_per_share_price: transaction_per_share_price,
      transaction_value: transaction_value,
      market_cap_percentage_value: market_cap_percentage_value
    }
  end
end
