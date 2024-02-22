defmodule InsiderTraderReporterService.Company do
  import SweetXml

  alias InsiderTraderReporterService.Clients.SecClient

  def get_company_info(company_name) do
    case SecClient.fetch_companies_info() do
      {:ok, resp_body} ->
        {:ok, decoded_response} = Jason.decode(resp_body)
        company_info = decoded_response["data"]
        |> Enum.find(nil, fn data_set -> Enum.at(data_set, 1) === company_name["company_name"] end)

        %{company_info: company_info}

      {:error, message} ->
        {:error, message}
    end
  end

  def get_company_filings(company_name) do
    %{company_info: company_info} = get_company_info(company_name)
    company_cik = hd(company_info)

    case SecClient.fetch_company_filings_list(company_cik) do
      {:ok, resp_body} ->
        company_filing = filter_relevant_filings(resp_body)
        %{company_filings: company_filing}

      {:error, message} ->
        {:error, message}
    end
  end

  defp filter_relevant_filings(company_filings) do
    SweetXml.parse(company_filings, namespace_conformant: true)
    |> xpath(
      ~x"//entry/content"l,
      filing_type: ~x"./filing-type/text()"s,
      filing_href: ~x"./filing-href/text()"s
    )
    |> Enum.filter(fn(map) -> Map.get(map, :filing_type) in ["3", "4", "5"] end)
  end
end
