defmodule InsiderTraderReporterService.Form do
  import SweetXml

  alias InsiderTraderReporterService.Clients.SecClient
  alias InsiderTraderReporterService.Company
  alias InsiderTraderReporterService.InsiderTrader
  alias InsiderTraderReporterService.Transaction
  alias InsiderTraderReporterService.MarketCap

  @sec_base_url "https://www.sec.gov"

  @derive(Jason.Encoder)
  defstruct [
    insider_trader_data: %InsiderTrader{},
    transaction_data: %Transaction{},
    form_url: ""
  ]

  defp new(insider_trader_data, transaction_data, form_url) do
    %InsiderTraderReporterService.Form{
      insider_trader_data: insider_trader_data,
      transaction_data: transaction_data,
      form_url: form_url
    }
  end

  def get_company_forms_data(company_name, company_ticker) do
    company_market_cap_values = MarketCap.get_market_cap_values(company_ticker)
    {:company_forms_urls, company_forms_urls} = get_company_forms_urls(company_name)
    company_forms_urls
    |> Enum.map(fn(form_href) -> get_company_form_data(form_href, company_market_cap_values) end)
    |> List.flatten()
  end

  def get_company_forms_urls(company_name) do
    {:company_data, company_data} = Company.get_company_data(company_name)
    company_cik = company_data.company_cik
    case SecClient.fetch_company_forms_list(company_cik) do
      {:ok, resp_body} ->
        {:company_forms_urls, filter_relevant_forms_urls(resp_body)}

      {:error, message} ->
        {:error, message}
    end
  end

  defp filter_relevant_forms_urls(company_forms_urls) do
    SweetXml.parse(company_forms_urls, namespace_conformant: true)
    |> xpath(
      ~x"//entry/content"l,
      form_type: ~x"./filing-type/text()"s,
      form_href: ~x"./filing-href/text()"s
    )
    |> Enum.filter(fn(map) -> Map.get(map, :form_type) in ["4"] end)
    |> Enum.map(fn(map) -> Map.get(map, :form_href) end)
  end

  defp get_company_form_data(form_url, company_market_cap_values) do
    {:ok, response} = SecClient.fetch_company_forms_page(form_url)
    {:ok, parsed_page} = Floki.parse_document(response)
    partial_form_url = extract_form_url(parsed_page)
    form_url = "#{@sec_base_url}#{partial_form_url}"
    {:ok, forms_data_xml} = SecClient.fetch_company_form_data(form_url)
    parse_and_filter_forms_data(forms_data_xml, form_url, company_market_cap_values)
  end

  defp extract_form_url(parsed_page) do
    parsed_page
    |> Floki.find("a")
    |> Enum.filter(fn(tag) -> Floki.text(tag) =~ ~r/.xml/ end)
    |> Enum.find_value(fn(tag) -> Floki.attribute(tag, "href") end)
  end

  defp parse_and_filter_forms_data(form_data_xml, form_url, company_market_cap_values) do
    form_data =  XmlToMap.naive_map(form_data_xml)
    |> Map.get("ownershipDocument", %{})
    insider_trader_data = InsiderTrader.get_insider_trader_data(form_data)
    Transaction.get_transactions_data(form_data, company_market_cap_values)
    |> Enum.map(fn(transaction_data) -> new(insider_trader_data, transaction_data, form_url) end)
  end
end
