defmodule InsiderTraderReporterService.InsiderTrading do
  alias InsiderTraderReporterService.Clients.SecClient
  alias InsiderTraderReporterService.Company

  @sec_base_url "https://www.sec.gov"

  def get_insider_trading_report_data(company_name) do
    %{company_info: [company_cik, _company_name, company_ticker, _exchange]} = Company.get_company_info(company_name)
    %{company_filings: company_filings} = Company.get_company_filings(company_name)
    %{company_market_cap: company_market_cap} = Company.get_company_market_cap_value(company_ticker)
    company_filings_data = company_filings
    |> Enum.map(fn(map) -> get_company_filing_data(map[:filing_href]) end)
    |> flat_transactions_data_list()
    insider_trading_transactions_data = %{
      company_data: %{
        company_name: Map.get(company_name, "company_name", ""),
        company_ticker: company_ticker,
        company_cik: company_cik,
        company_market_cap: company_market_cap
      },
      company_filings_data: company_filings_data
    }
    %{insider_trading_transactions_data: insider_trading_transactions_data}
  end

  defp flat_transactions_data_list(transactions_data_lists) do
      transactions_data_lists
      |> Enum.flat_map(fn(x) -> x end)
      |> Enum.map(fn %{transaction_data: transaction_data} -> %{transaction_data: transaction_data} end)
  end

  defp get_company_filing_data(filing_url) do
    {:ok, response} = SecClient.fetch_company_filings_page(filing_url)
    {:ok, parsed_page} = Floki.parse_document(response)
    [[partial_filing_url]] = extract_filing_url(parsed_page)
    filing_url = "#{@sec_base_url}#{partial_filing_url}"
    {:ok, filings_data_xml} = SecClient.fetch_company_filing_data(filing_url)
    filings_data = parse_and_filter_filings_data(filings_data_xml, filing_url)
    split_filing_data_into_transaction_data(filings_data)
  end

  defp extract_filing_url(parsed_page) do
    parsed_page
    |> Floki.find("a")
    |> Enum.filter(fn(tag) -> Floki.text(tag) =~ ~r/.xml/ end)
    |> Enum.map(fn(tag) -> Floki.attribute(tag, "href") end)
  end

  defp parse_and_filter_filings_data(filing_data_xml, filing_url) do
    filing_data =  XmlToMap.naive_map(filing_data_xml)
    |> Map.get("ownershipDocument", %{})
    {insider_name, insider_title} =
      get_insider_data(filing_data)

    {transactions_shares_amounts, transactions_per_share_prices, transactions_dates} =
      get_transactions_data(filing_data)
    %{
      transaction_date: transactions_dates,
      insider_name: insider_name,
      insider_title: insider_title,
      transaction_shares_amount: transactions_shares_amounts,
      transaction_per_share_price: transactions_per_share_prices,
      filing_url: filing_url
    }
  end

  defp split_filing_data_into_transaction_data(filings_data) do
    filing_transactions_dates = filings_data[:transaction_date]
    filing_transactions_share_amounts = filings_data[:transaction_shares_amount]
    filing_transactions_per_share_prices = filings_data[:transaction_per_share_price]
    Enum.zip([filing_transactions_dates, filing_transactions_share_amounts, filing_transactions_per_share_prices])
    |> Enum.map(fn(values) -> create_transactions_data_map(filings_data, values) end)
  end

  defp create_transactions_data_map(filings_data, {date, amount, price}) do
    %{
      transaction_data: %{
        transaction_date: date,
        insider_name: filings_data[:insider_name],
        insider_title: filings_data[:insider_title],
        transaction_shares_amount: amount,
        transaction_per_share_price: price,
        transaction_value: amount * price,
        filing_url: filings_data[:filing_url]
      }
    }
  end

  defp number_type(str) when is_binary(str) do
    cond do
      String.match?(str, ~r/^-?\d+$/) -> :integer
      String.match?(str, ~r/^-?\d+\.\d+$/) -> :float
      true -> 0
    end
  end

  defp number_type(str), do: str

  defp convert_string_to_number(str_value) do
    case number_type(str_value) do
      :integer -> String.to_integer(str_value)
      :float -> String.to_float(str_value)
      _ -> 0
    end
  end

  defp get_insider_data(parsed_xml) do
    reporter_data = parsed_xml
    |> Map.get("reportingOwner", %{})
    insider_name = reporter_data
    |> Map.get("reportingOwnerId", %{})
    |> Map.get("rptOwnerName", "")
    insider_title = reporter_data
    |> Map.get("reportingOwnerRelationship", %{})
    |> Map.get("officerTitle", "")
    {insider_name, insider_title}
  end

  defp get_transactions_data(filing_data) do
    {nd_transactions_shares_amounts, nd_transactions_per_share_prices, nd_transactions_dates} =
      get_transactions_data_by_transaction_type(filing_data, "nonDerivativeTable", "nonDerivativeTransaction")
    {d_transactions_shares_amounts, d_transactions_per_share_prices, d_transactions_dates} =
      get_transactions_data_by_transaction_type(filing_data, "derivativeTable", "derivativeTransaction")
    transactions_shares_amounts = nd_transactions_shares_amounts ++ d_transactions_shares_amounts
    transactions_per_share_prices = nd_transactions_per_share_prices ++ d_transactions_per_share_prices
    transactions_dates = nd_transactions_dates ++ d_transactions_dates
    {transactions_shares_amounts, transactions_per_share_prices, transactions_dates}
  end

  defp get_transactions_data_by_transaction_type(filing_data, first_key, second_key) do
    transactions_data =
      get_transactions_list(filing_data, first_key, second_key)
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

  def check_and_adjust_collection_type(transactions_data, expected_type) when expected_type == "map" do
    case is_map(transactions_data) do
      true -> transactions_data
      false -> %{}
    end
  end

  def check_and_adjust_collection_type(transactions_data, expected_type) when expected_type == "list" do
    case is_list(transactions_data) do
      true -> transactions_data
      false -> [transactions_data]
    end
  end
end
