defmodule InsiderTraderReporterService.Companies do
  alias InsiderTraderReporterService.Clients.SecClient

  def get_company_info(company_name) do
    case SecClient.fetch_companies_info() do
      {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} ->
        {:ok, decoded_response} = Jason.decode(resp_body)
        company_data = decoded_response["data"]
        |> Enum.find(nil, fn data_set -> Enum.at(data_set, 1) === company_name["company_name"] end)
        %{company_data: company_data}

      {:ok, %HTTPoison.Response{status_code: code, body: _resp_body}} when code !== 200 ->
        {:error, "Failed to retrieve company data! | Status code: #{code}"}

      {:error, reason} ->
        {:error, "Failed to retrieve company data! | Reason: #{reason}"}

      _ ->
        {:error, "Failed to retrieve company data! | Unknown Reason"}
    end
  end
end
