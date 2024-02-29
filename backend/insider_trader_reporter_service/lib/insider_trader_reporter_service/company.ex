defmodule InsiderTraderReporterService.Company do
  alias InsiderTraderReporterService.Clients.SecClient

  @derive(Jason.Encoder)
  defstruct [
      company_name: "",
      company_ticker: "",
      company_cik: ""
  ]

  defp new(company_name, company_ticker, company_cik) do
    %InsiderTraderReporterService.Company{
      company_name: company_name,
      company_ticker: company_ticker,
      company_cik: company_cik
    }
  end

  def get_company_data(company_name) do
    company_name = Map.get(company_name, "company_name", "")
    case SecClient.fetch_companies_info() do
      {:ok, resp_body} ->
        {:ok, decoded_response} = Jason.decode(resp_body)
        filtered_company_data = decoded_response["data"]
        |> Enum.find(nil, fn data_set -> Enum.at(data_set, 1) === company_name end)
        [company_cik, company_name, company_ticker, _exchange] = filtered_company_data
        company_data = new(company_name, company_ticker, company_cik)
        {:company_data, company_data}

      {:error, message} ->
        {:error, message}
    end
  end
end
