defmodule InsiderTraderReporterService.InsiderTrading do
  alias InsiderTraderReporterService.Company
  alias InsiderTraderReporterService.Form

  defstruct [
    insider_trading_data: %{
      company_data: %Company{},
      company_forms_data: %Form{}
    }
  ]

  def get_insider_trading_report_data(company_name) do
    {:company_data, company_data} = Company.get_company_data(company_name)
    company_market_cap = company_data.company_market_cap
    company_forms_data = Form.get_company_forms_data(company_name, company_market_cap)
    insider_trading_transactions_data = %{
      company_data: %{
        company_name: company_data.company_name,
        company_ticker: company_data.company_ticker,
        company_cik: company_data.company_cik,
        company_market_cap: company_data.company_market_cap
      },
      company_forms_data: company_forms_data
    }
    %{insider_trading_transactions_data: insider_trading_transactions_data}
  end
end
