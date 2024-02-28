defmodule InsiderTraderReporterServiceWeb.InsiderView do
  use InsiderTraderReporterServiceWeb, :view

  def render("companyData.json", %{company_data: company_data}) do
    %{
      company_data: company_data
    }
  end

  def render("companyForms.json", %{company_forms_urls: company_forms_urls}) do
    %{
      forms: company_forms_urls,
    }
  end

  def render("companyInsiderTradingData.json", %{insider_trading_transactions_data: insider_trading_transactions_data}) do
    %{
      insider_trading_transactions_data: insider_trading_transactions_data,
    }
  end
end
