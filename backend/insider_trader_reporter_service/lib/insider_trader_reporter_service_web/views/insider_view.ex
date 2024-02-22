defmodule InsiderTraderReporterServiceWeb.InsiderView do
  use InsiderTraderReporterServiceWeb, :view

  def render("companyData.json", %{company_data: company_data}) do
    [company_cik, company_name, company_ticker | _company_data] = company_data
    %{
      cik: company_cik,
      name: company_name,
      ticker: company_ticker,
    }
  end

  def render("companyFilings.json", %{company_filings: company_filings}) do
    %{
      filings: company_filings,
    }
  end

  def render("companyFilingsData.json", %{insider_trading_transactions_data: insider_trading_transactions_data}) do
    %{
      insider_trading_transactions_data: insider_trading_transactions_data,
    }
  end
end
