defmodule InsiderTraderReporterServiceWeb.InsiderController do
  use InsiderTraderReporterServiceWeb, :controller

  alias InsiderTraderReporterService.Company
  alias InsiderTraderReporterService.Form
  alias InsiderTraderReporterService.InsiderTrading

  action_fallback InsiderTraderReporterServiceWeb.FallbackController

  def get_company_data(conn, company_name) do
    case Company.get_company_data(company_name) do
      {:company_data, nil} -> {:error, :not_found}
      {:company_data, company_data} ->
        render(conn, "companyData.json", company_data: company_data)
      {:error, message} -> {:error, message}
      _ -> {:error, "Unexpected error"}
    end
  end

  def get_company_forms_urls(conn, company_name) do
    case Form.get_company_forms_urls(company_name) do
      {:company_forms_urls, company_forms_urls} ->
        render(conn, "companyForms.json", company_forms_urls: company_forms_urls)
      {:error, message} -> {:error, message}
      _ -> {:error, "Unexpected error"}
    end
  end

  def get_insider_trading_report_data(conn, company_name) do
    case InsiderTrading.get_insider_trading_report_data(company_name) do
      %{insider_trading_transactions_data: insider_trading_transactions_data} ->
        render(conn, "companyInsiderTradingData.json", insider_trading_transactions_data: insider_trading_transactions_data)
      {:error, message} -> {:error, message}
      _ -> {:error, "Unexpected error"}
    end
  end
end
