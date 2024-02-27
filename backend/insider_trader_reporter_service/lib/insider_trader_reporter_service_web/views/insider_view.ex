defmodule InsiderTraderReporterServiceWeb.InsiderView do
  use InsiderTraderReporterServiceWeb, :view

  def render("companyData.json", %{company_data: company_data}) do
    %{
      company_data: company_data
    }
  end

  def render("companyForms.json", %{company_forms: company_forms}) do
    %{
      forms: company_forms,
    }
  end

  def render("companyFilingsData.json", %{insider_trading_transactions_data: insider_trading_transactions_data}) do
    %{
      insider_trading_transactions_data: insider_trading_transactions_data,
    }
  end
end
