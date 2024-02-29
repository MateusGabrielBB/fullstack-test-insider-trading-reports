defmodule InsiderTraderReporterService.Clients.YahooFinanceClient do
  alias InsiderTraderReporterService.Clients.ClientHelper

  @yahoo_finance_api_base_url "https://query2.finance.yahoo.com"
  @yahoo_finance_cookies_url "https://fc.yahoo.com"
  @yahoo_finance_crumble_url "/v1/test/getcrumb"
  @yahoo_finance_user_agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"

  def fetch_company_historical_prices(company_ticker, period_start, period_end) do
    endpoint = fetch_market_historical_values_url(company_ticker, period_start, period_end)
    HTTPoison.get(endpoint)
    |> ClientHelper.handle_client_response()
  end

  def fetch_company_shares_outstanding(company_ticker) do
    {req_cookie, req_crumble} = fetch_cookie_and_crumble()
    endpoint = fetch_company_shares_outstanding_url(company_ticker, req_crumble)
    req_header = [{"Cookie", req_cookie}, {"User-agent", @yahoo_finance_user_agent}]
    HTTPoison.get(endpoint, req_header)
    |> ClientHelper.handle_client_response()
  end

  defp fetch_cookie_and_crumble() do
    {:ok, %HTTPoison.Response{headers: resp_headers}} = HTTPoison.get(@yahoo_finance_cookies_url)
    req_cookie_value = get_cookie_from_response(resp_headers)
    get_crumble_endpoint = "#{@yahoo_finance_api_base_url}#{@yahoo_finance_crumble_url}"
    req_header = [{"Cookie", req_cookie_value}, {"User-agent", @yahoo_finance_user_agent}]
    {:ok, crumble_value} = HTTPoison.get(get_crumble_endpoint, req_header)
    |> ClientHelper.handle_client_response()
    {req_cookie_value, crumble_value}
  end

  defp get_cookie_from_response(resp_headers) do
    {"Set-Cookie", resp_cookie} = resp_headers
    |> Enum.find(fn(tuple) -> elem(tuple, 0) === "Set-Cookie" end)
    resp_cookie
    |> String.split(";")
    |> hd()
  end

  defp fetch_market_historical_values_url(company_ticker, period_start, period_end) do
    "#{@yahoo_finance_api_base_url}/v7/finance/download/#{company_ticker}?period1=#{period_start}&period2=#{period_end}&interval=1d&events=history&includeAdjustedClose=true"
  end

  defp fetch_company_shares_outstanding_url(company_ticker, crumble) do
    "#{@yahoo_finance_api_base_url}/v7/finance/options/#{company_ticker}?crumb=#{crumble}"
  end
end
