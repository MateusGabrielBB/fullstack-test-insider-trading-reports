defmodule InsiderTraderReporterService.Company do

  alias InsiderTraderReporterService.Clients.SecClient
  alias InsiderTraderReporterService.Clients.YahooFinanceClient

  def get_company_info(company_name) do
    company_name = Map.get(company_name, "company_name", "")
    case SecClient.fetch_companies_info() do
      {:ok, resp_body} ->
        {:ok, decoded_response} = Jason.decode(resp_body)
        company_info = decoded_response["data"]
        |> Enum.find(nil, fn data_set -> Enum.at(data_set, 1) === company_name end)

        {:company_info, company_info}

      {:error, message} ->
        {:error, message}
    end
  end

  def get_company_market_cap_value(company_ticker) do
    case YahooFinanceClient.fetch_market_cap_value(company_ticker) do
      {:ok, resp_body} ->
        {:ok, decoded_response} = Jason.decode(resp_body)
        company_market_cap = filter_company_market_cap_value(decoded_response)
        {:company_market_cap, company_market_cap}

      {:error, message} ->
        {:error, message}
    end
  end

  defp filter_company_market_cap_value(company_details) do
    company_details
        |> Map.get("quoteSummary")
        |> Map.get("result")
        |> List.first(%{})
        |> Map.get("summaryDetail", %{})
        |> Map.get("marketCap", %{})
        |> Map.get("raw", 0)
  end
end
