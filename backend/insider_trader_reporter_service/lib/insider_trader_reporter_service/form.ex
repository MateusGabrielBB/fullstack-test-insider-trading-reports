defmodule InsiderTraderReporterService.Form do
  import SweetXml

  alias InsiderTraderReporterService.Clients.SecClient
  alias InsiderTraderReporterService.Company
  alias InsiderTraderReporterService.InsiderTrader
  alias InsiderTraderReporterService.Transaction

  @sec_base_url "https://www.sec.gov"
  @market_cap_divisor 100
  @percentage_notation_precision 9

  defstruct [
    transaction_data: %{
      insider_trader_data: %InsiderTrader{},
      transaction_data: %Transaction{}
    },
    form_url: ""
  ]

  def get_company_forms_data(company_name, company_market_cap) do
    {:company_forms, company_forms} = get_company_forms(company_name)
    company_forms
    |> Enum.map(fn(map) -> get_company_form_data(map[:form_href], company_market_cap) end)
    |> flat_transactions_data_list()
  end

  defp flat_transactions_data_list(transactions_data_lists) do
    transactions_data_lists
    |> Enum.flat_map(fn(x) -> x end)
    |> Enum.map(fn %{transaction_data: transaction_data} -> %{transaction_data: transaction_data} end)
  end

  def get_company_forms(company_name) do
    {:company_data, company_data} = Company.get_company_data(company_name)
    company_cik = company_data.company_cik
    case SecClient.fetch_company_forms_list(company_cik) do
      {:ok, resp_body} ->
        {:company_forms, filter_relevant_forms(resp_body)}

      {:error, message} ->
        {:error, message}
    end
  end

  defp filter_relevant_forms(company_forms) do
    SweetXml.parse(company_forms, namespace_conformant: true)
    |> xpath(
      ~x"//entry/content"l,
      form_type: ~x"./filing-type/text()"s,
      form_href: ~x"./filing-href/text()"s
    )
    |> Enum.filter(fn(map) -> Map.get(map, :form_type) in ["4"] end)
  end

  defp get_company_form_data(form_url, company_market_cap) do
    {:ok, response} = SecClient.fetch_company_forms_page(form_url)
    {:ok, parsed_page} = Floki.parse_document(response)
    [[partial_form_url]] = extract_form_url(parsed_page)
    form_url = "#{@sec_base_url}#{partial_form_url}"
    {:ok, forms_data_xml} = SecClient.fetch_company_form_data(form_url)
    forms_data = parse_and_filter_forms_data(forms_data_xml, form_url)
    split_form_data_by_transaction(forms_data, company_market_cap)
  end

  defp extract_form_url(parsed_page) do
    parsed_page
    |> Floki.find("a")
    |> Enum.filter(fn(tag) -> Floki.text(tag) =~ ~r/.xml/ end)
    |> Enum.map(fn(tag) -> Floki.attribute(tag, "href") end)
  end

  defp parse_and_filter_forms_data(form_data_xml, form_url) do
    form_data =  XmlToMap.naive_map(form_data_xml)
    |> Map.get("ownershipDocument", %{})
    {insider_name, insider_title} =
      get_insider_data(form_data)

    {transactions_shares_amounts, transactions_per_share_prices, transactions_dates} =
      get_transactions_data(form_data)
    %{
      transaction_date: transactions_dates,
      insider_name: insider_name,
      insider_title: insider_title,
      transaction_shares_amount: transactions_shares_amounts,
      transaction_per_share_price: transactions_per_share_prices,
      form_url: form_url
    }
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

  defp get_transactions_data(form_data) do
    {nd_transactions_shares_amounts, nd_transactions_per_share_prices, nd_transactions_dates} =
      get_transactions_data_by_transaction_type(form_data, "nonDerivativeTable", "nonDerivativeTransaction")
    {d_transactions_shares_amounts, d_transactions_per_share_prices, d_transactions_dates} =
      get_transactions_data_by_transaction_type(form_data, "derivativeTable", "derivativeTransaction")
    transactions_shares_amounts = nd_transactions_shares_amounts ++ d_transactions_shares_amounts
    transactions_per_share_prices = nd_transactions_per_share_prices ++ d_transactions_per_share_prices
    transactions_dates = nd_transactions_dates ++ d_transactions_dates
    {transactions_shares_amounts, transactions_per_share_prices, transactions_dates}
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

  defp get_transactions_list(transactions_data, first_key, second_key) do
    transactions_data
    |> Map.get(first_key, %{})
    |> check_and_adjust_collection_type("map")
    |> Map.get(second_key, [])
    |> check_and_adjust_collection_type("list")
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

  defp split_form_data_by_transaction(forms_data, company_market_cap) do
    form_transactions_dates = forms_data[:transaction_date]
    form_transactions_share_amounts = forms_data[:transaction_shares_amount]
    form_transactions_per_share_prices = forms_data[:transaction_per_share_price]
    Enum.zip([form_transactions_dates, form_transactions_share_amounts, form_transactions_per_share_prices])
    |> Enum.map(fn(values) -> create_transactions_data_map(forms_data, values, company_market_cap) end)
  end

  defp create_transactions_data_map(forms_data, {date, amount, price}, company_market_cap) do
    transaction_value = amount * price
    market_cap_percentage_value = (transaction_value/company_market_cap) * @market_cap_divisor
    formatted_market_cap_percentage_value = convert_to_percentage_notation(market_cap_percentage_value)
    %{
      transaction_data: %{
        transaction_date: date,
        insider_name: forms_data[:insider_name],
        insider_title: forms_data[:insider_title],
        transaction_shares_amount: amount,
        transaction_per_share_price: price,
        transaction_value: transaction_value,
        market_cap_percentage_value: formatted_market_cap_percentage_value,
        form_url: forms_data[:form_url]
      }
    }
  end

  defp convert_to_percentage_notation(market_cap_percentage_value) when market_cap_percentage_value != 0 do
    percentage_notation = market_cap_percentage_value
    |> Decimal.from_float()
    |> Decimal.round(@percentage_notation_precision)
    "#{percentage_notation}%"
  end

  defp convert_to_percentage_notation(_market_cap_percentage_value) do
    "0.0%"
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
end
