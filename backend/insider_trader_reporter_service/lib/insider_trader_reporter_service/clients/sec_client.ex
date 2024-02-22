defmodule InsiderTraderReporterService.Clients.SecClient do
  @sec_request_headers [{"User-Agent", "trading/0.1.0"}, {"Accept", "*/*"}]

  def fetch_companies_info() do
    endpoint = "https://www.sec.gov/files/company_tickers_exchange.json"
    HTTPoison.get(endpoint, @sec_request_headers)
  end
end
