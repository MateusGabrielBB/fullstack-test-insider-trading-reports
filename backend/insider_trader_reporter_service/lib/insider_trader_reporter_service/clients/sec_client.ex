defmodule InsiderTraderReporterService.Clients.SecClient do
  alias InsiderTraderReporterService.Clients.ClientHelper

  @sec_request_headers [{"User-Agent", "trading/0.1.0"}, {"Accept", "*/*"}]
  @sec_base_url "https://www.sec.gov"

  def fetch_companies_info() do
    endpoint = fetch_company_info_url()
    HTTPoison.get(endpoint, @sec_request_headers)
    |> ClientHelper.handle_client_response()
  end

  def fetch_company_forms_list(company_cik) do
    endpoint = fetch_company_filings_url(company_cik)
    HTTPoison.get(endpoint, @sec_request_headers)
    |> ClientHelper.handle_client_response()
  end

  def fetch_company_forms_page(endpoint) do
    HTTPoison.get(endpoint, @sec_request_headers)
    |> ClientHelper.handle_client_response()
  end

  def fetch_company_form_data(endpoint) do
    HTTPoison.get(endpoint, @sec_request_headers)
    |> ClientHelper.handle_client_response()
  end

  defp fetch_company_info_url(), do: "#{@sec_base_url}/files/company_tickers_exchange.json"

  defp fetch_company_filings_url(company_cik) do
    "#{@sec_base_url}/cgi-bin/browse-edgar?action=getcompany&CIK=#{company_cik}&owner=&count=15&output=atom"
  end
end
