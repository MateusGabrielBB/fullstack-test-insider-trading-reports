defmodule InsiderTraderReporterService.Transaction do
  @market_cap_divisor 100
  @percentage_notation_precision 9

  @derive(Jason.Encoder)
  defstruct [
    transaction_date: "",
    transaction_shares_amount: 0,
    transaction_per_share_price: 0.0,
    transaction_value: 0.0,
    market_cap_percentage_value: "0.0%"
  ]

  defp new(
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

  def get_transactions_data(form_data, company_market_cap) do
    {nd_transactions_shares_amounts, nd_transactions_per_share_prices, nd_transactions_dates} =
      get_transactions_data_by_transaction_type(form_data, "nonDerivativeTable", "nonDerivativeTransaction")
    {d_transactions_shares_amounts, d_transactions_per_share_prices, d_transactions_dates} =
      get_transactions_data_by_transaction_type(form_data, "derivativeTable", "derivativeTransaction")
    transactions_shares_amounts = nd_transactions_shares_amounts ++ d_transactions_shares_amounts
    transactions_per_share_prices = nd_transactions_per_share_prices ++ d_transactions_per_share_prices
    transactions_dates = nd_transactions_dates ++ d_transactions_dates
    split_values_lists_by_transaction(transactions_dates, transactions_shares_amounts, transactions_per_share_prices, company_market_cap)
  end

  defp get_transactions_data_by_transaction_type(form_data, first_key, second_key) do
    transactions_data =
      get_transactions_list(form_data, first_key, second_key)
    transactions_shares_amounts =
      get_transactions_per_share_prices(transactions_data, "transactionAmounts", "transactionShares")
    transactions_per_share_prices =
      get_transactions_per_share_prices(transactions_data, "transactionAmounts", "transactionPricePerShare")
    transactions_dates = transactions_data
    |> Enum.map(fn(map) ->
      extract_transaction_field_value_from_map(map, "transactionDate")
    end)
    {transactions_shares_amounts, transactions_per_share_prices, transactions_dates}
  end

  defp split_values_lists_by_transaction(transactions_dates, transactions_shares_amounts, transactions_per_share_prices, company_market_cap) do
    Enum.zip([transactions_dates, transactions_shares_amounts, transactions_per_share_prices])
    |> Enum.map(fn(values) -> create_transactions_structs(values, company_market_cap) end)
  end

  defp get_transactions_list(transactions_data, first_key, second_key) do
    transactions_data
    |> Map.get(first_key, %{})
    |> check_and_adjust_collection_type("map")
    |> Map.get(second_key, [])
    |> check_and_adjust_collection_type("list")
  end

  defp get_transactions_per_share_prices(transactions_list, first_key, second_key) do
    transactions_list
    |> Enum.map(fn(map) ->
      extract_transaction_field_value_from_map(map, first_key, second_key)
      |> convert_string_to_number()
    end)
  end

  defp extract_transaction_field_value_from_map(map, first_key, second_key) do
    map
    |> Map.get(first_key, %{})
    |> Map.get(second_key, %{})
    |> Map.get("value", 0)
  end

  defp extract_transaction_field_value_from_map(map, key) do
    map
    |> Map.get(key, %{})
    |> Map.get("value", "")
  end

  defp check_and_adjust_collection_type(transactions_data, expected_type) when expected_type == "map" do
    case is_map(transactions_data) do
      true -> transactions_data
      false -> %{}
    end
  end

  defp check_and_adjust_collection_type(transactions_data, expected_type) when expected_type == "list" do
    case is_list(transactions_data) do
      true -> transactions_data
      false -> [transactions_data]
    end
  end

  defp convert_string_to_number(str_value) do
    case number_type(str_value) do
      :integer -> String.to_integer(str_value)
      :float -> String.to_float(str_value)
      _ -> 0
    end
  end

  defp create_transactions_structs({transaction_date, transaction_shares_amount, transaction_per_share_price}, company_market_cap) do
    transaction_value = transaction_shares_amount * transaction_per_share_price
    market_cap_percentage_value = (transaction_value/company_market_cap) * @market_cap_divisor
    formatted_market_cap_percentage_value = convert_to_percentage_notation(market_cap_percentage_value)
    new(transaction_date,transaction_shares_amount, transaction_per_share_price, transaction_value, formatted_market_cap_percentage_value)
  end

  defp number_type(str) when is_binary(str) do
    cond do
      String.match?(str, ~r/^-?\d+$/) -> :integer
      String.match?(str, ~r/^-?\d+\.\d+$/) -> :float
      true -> 0
    end
  end

  defp number_type(str), do: str

  defp convert_to_percentage_notation(market_cap_percentage_value) when market_cap_percentage_value != 0 do
    percentage_notation = market_cap_percentage_value
    |> Decimal.from_float()
    |> Decimal.round(@percentage_notation_precision)
    "#{percentage_notation}%"
  end

  defp convert_to_percentage_notation(_market_cap_percentage_value) do
    "0.0%"
  end
end
