defmodule InsiderTraderReporterServiceWeb.InsiderController do
  use InsiderTraderReporterServiceWeb, :controller

  alias InsiderTraderReporterService.Company
  alias InsiderTraderReporterService.InsiderTrading

  action_fallback InsiderTraderReporterServiceWeb.FallbackController

  def get_company_info(conn, company_name) do
    case Company.get_company_info(company_name) do
      %{company_info: nil} -> {:error, :not_found}
      %{company_info: company_info} ->
        render(conn, "companyData.json", company_data: company_info)
      {:error, message} -> {:error, message}
      _ -> {:error, "Unexpected error"}
    end
  end

  def get_company_filings(conn, company_name) do
    case Company.get_company_filings(company_name) do
      %{company_filings: company_filings} ->
        render(conn, "companyFilings.json", company_filings: company_filings)
      {:error, message} -> {:error, message}
      _ -> {:error, "Unexpected error"}
    end
  end

  def get_insider_trading_transactions_data(conn, company_name) do
    case InsiderTrading.get_insider_trading_transactions_data(company_name) do
      %{insider_trading_transactions_data: insider_trading_transactions_data} ->
        render(conn, "companyFilingsData.json", insider_trading_transactions_data: insider_trading_transactions_data)
      {:error, message} -> {:error, message}
      _ -> {:error, "Unexpected error"}
    end
  end
end
