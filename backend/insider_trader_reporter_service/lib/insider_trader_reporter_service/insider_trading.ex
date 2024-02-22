defmodule InsiderTraderReporterService.InsiderTrading do
  import SweetXml

  alias InsiderTraderReporterService.Clients.SecClient
  alias InsiderTraderReporterService.Company

  def get_insider_trading_transactions_data(company_name) do
    %{company_info: [company_cik, _company_name, company_ticker, _exchange]} = Company.get_company_info(company_name)
    %{company_filings: company_filings} = Company.get_company_filings(company_name)
    %{company_market_cap: company_market_cap} = Company.get_company_market_cap_value(company_ticker)
    company_filings_data = company_filings
    |> Enum.map(fn(map) -> get_company_filing_data(map[:filing_href]) end)
    |> flat_transactions_data_list()

    insider_trading_transactions_data = %{
      company_data: %{
        company_name: company_name["company_name"],
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
    [[fetch_filing_data_url_part]] = extract_fetch_filing_data_url_part(parsed_page)
    {:ok, filing_data} = SecClient.fetch_company_filings_data(fetch_filing_data_url_part)
    parsed_filing_data = parse_and_filter_company_filings_data(filing_data, fetch_filing_data_url_part)
    split_filing_data_into_trasaction_data(parsed_filing_data)
  end

  defp extract_fetch_filing_data_url_part(parsed_page) do
    parsed_page
    |> Floki.find("a")
    |> Enum.filter(fn(tag) -> Floki.text(tag) =~ ~r/.xml/ end)
    |> Enum.map(fn(tag) -> Floki.attribute(tag, "href") end)
  end

  defp parse_and_filter_company_filings_data(filing_data, fetch_filing_data_url_part) do
    SweetXml.parse(filing_data, namespace_conformant: true)
    |> xpath(
      ~x"//ownershipDocument",
      transaction_date: ~x"./nonDerivativeTable/nonDerivativeTransaction/transactionDate/value/text()"ls,
      insider_name: ~x"./reportingOwner/reportingOwnerId/rptOwnerName/text()"s,
      insider_title: ~x"./reportingOwner/reportingOwnerRelationship/officerTitle/text()"s,
      transaction_shares_amount: ~x"./nonDerivativeTable/nonDerivativeTransaction/transactionAmounts/transactionShares/value/text()"lI,
      transaction_shares_value: ~x"./nonDerivativeTable/nonDerivativeTransaction/transactionAmounts/transactionPricePerShare/value/text()"lF
    )
    |> Enum.into(%{filing_url_reference: fetch_filing_data_url_part})
  end

  defp split_filing_data_into_trasaction_data(parsed_filing_data) do
    filing_transaction_dates = parsed_filing_data[:transaction_date]
    filing_transaction_share_amounts = parsed_filing_data[:transaction_shares_amount]
    filing_transaction_share_values = parsed_filing_data[:transaction_shares_value]
    Enum.zip([filing_transaction_dates, filing_transaction_share_amounts, filing_transaction_share_values])
    |> Enum.map(fn(lists) -> create_transactions_data_map(parsed_filing_data, lists) end)
  end

  defp create_transactions_data_map(filings_data, {date, amount, value}) do
    %{
      transaction_data: %{
        transaction_date: date,
        insider_name: filings_data[:insider_name],
        insider_title: filings_data[:insider_title],
        transaction_shares_amount: amount,
        transaction_shares_value: value,
        filing_url_reference: filings_data[:filing_url_reference]
      }
    }
  end
end
