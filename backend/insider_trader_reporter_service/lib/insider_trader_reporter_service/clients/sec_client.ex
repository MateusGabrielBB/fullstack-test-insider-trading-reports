defmodule InsiderTraderReporterService.Clients.SecClient do
  @sec_request_headers [{"User-Agent", "trading/0.1.0"}, {"Accept", "*/*"}]
  @sec_base_url "https://www.sec.gov"

  def fetch_companies_info() do
    endpoint = fetch_company_info_url()
    request_response = HTTPoison.get(endpoint, @sec_request_headers)
    handle_client_response(request_response)
  end

  def fetch_company_filings_list(company_cik) do
    endpoint = fetch_company_filings_url(company_cik)
    request_response = HTTPoison.get(endpoint, @sec_request_headers)
    handle_client_response(request_response)
  end

  def fetch_company_filings_page(endpoint) do
    request_response = HTTPoison.get(endpoint, @sec_request_headers)
    handle_client_response(request_response)
  end

  def fetch_company_filings_data(endpoint) do
    request_response = HTTPoison.get(endpoint, @sec_request_headers)
    handle_client_response(request_response)
  end

  defp fetch_company_info_url(), do: "#{@sec_base_url}/files/company_tickers_exchange.json"

  defp fetch_company_filings_url(company_cik) do
    "#{@sec_base_url}/cgi-bin/browse-edgar?action=getcompany&CIK=#{company_cik}&owner=&count=15&output=atom"
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
