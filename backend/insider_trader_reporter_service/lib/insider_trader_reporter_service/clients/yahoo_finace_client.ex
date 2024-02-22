defmodule InsiderTraderReporterService.Clients.YahooFinaceClient do
  @yahoo_finance_base_url "https://query2.finance.yahoo.com"

  def fetch_market_cap_value(company_ticker) do
    endpoint = fetch_market_cap_value_url(company_ticker)
    request_response = HTTPoison.get(endpoint)
    handle_client_response(request_response)
  end

  defp fetch_market_cap_value_url(company_ticker) do
    "#{@yahoo_finance_base_url}/v10/finance/quoteSummary/?symbol=#{company_ticker}&modules=summaryDetail"
  end

  defp handle_client_response(client_response) do
    case client_response do
      {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} ->
        {:ok, resp_body}

      {:ok, %HTTPoison.Response{status_code: code, body: _resp_body}} when code !== 200 ->
        {:error, "Failed request! | Response Status code: #{code}"}

      {:error, reason} ->
        {:error, "Failed request! | Reason: #{reason}"}

      _ ->
        {:error, "Failed request! | Unknown Reason"}
    end
  end
end
