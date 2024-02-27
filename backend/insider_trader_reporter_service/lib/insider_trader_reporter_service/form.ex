defmodule InsiderTraderReporterService.Form do
  import SweetXml

  alias InsiderTraderReporterService.Clients.SecClient
  alias InsiderTraderReporterService.Company

  def get_company_forms(company_name) do
    %{company_info: company_info} = Company.get_company_info(company_name)
    company_cik = hd(company_info)
    case SecClient.fetch_company_forms_list(company_cik) do
      {:ok, resp_body} ->
        company_forms = filter_relevant_forms(resp_body)
        %{company_forms: company_forms}

      {:error, message} ->
        {:error, message}
    end
  end

  defp filter_relevant_forms(company_forms) do
    SweetXml.parse(company_forms, namespace_conformant: true)
    |> xpath(
      ~x"//entry/content"l,
      form_type: ~x"./filing-type/text()"s,
      form_href: ~x"./filing-href/text()"s
    )
    |> Enum.filter(fn(map) -> Map.get(map, :form_type) in ["4"] end)
  end
end
