defmodule InsiderTraderReporterService.MarketCap do
  alias NimbleCSV.RFC4180, as: CSV
  alias InsiderTraderReporterService.Clients.YahooFinanceClient

  def get_market_cap_values(company_ticker) do
    period_start = DateTime.utc_now()
    |> DateTime.add(-365, :day)
    |> DateTime.to_unix()
    period_end = DateTime.utc_now()
    |> DateTime.to_unix()
    company_shares_outstanding = get_company_shares_outstanding(company_ticker)
    get_company_historical_share_close_prices(period_start, period_end)
    |> Enum.map(fn(map) -> calculate_and_add_market_cap_to_map(map, company_shares_outstanding) end)
  end

  defp get_company_shares_outstanding(company_ticker) do
    {:ok, shares_outstanding_response} = YahooFinanceClient.fetch_company_shares_outstanding(company_ticker)
    {:ok, parsed_resp_body} = Jason.decode(shares_outstanding_response)
    parsed_resp_body
    |> Map.get("optionChain", %{})
    |> Map.get("result", [])
    |> List.first(%{})
    |> Map.get("quote", %{})
    |> Map.get("sharesOutstanding", 0)
  end

  defp get_company_historical_share_close_prices(period_start, period_end) do
    {:ok, company_historical_values_csv} = YahooFinanceClient.fetch_company_historical_prices(period_start, period_end)
    company_historical_values_csv
    |> CSV.parse_string()
    |> IO.inspect()
    |> Enum.map(fn(item) -> filter_date_and_close_share_prices(item) end)
  end

  defp calculate_and_add_market_cap_to_map(share_price_map, share_outstanding) do
    share_close_price = String.to_float(share_price_map[:close])
    market_cap = share_close_price * share_outstanding
    Map.put(share_price_map, :market_cap, market_cap)
  end

  defp filter_date_and_close_share_prices(share_prices_values) do
    [date, _open, _high, _low, close, _adj_close, _volume] = share_prices_values
    %{date: date, close: close}
  end
end
