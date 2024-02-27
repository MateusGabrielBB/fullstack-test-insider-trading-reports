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
    {:company_info, [company_cik, _company_name, company_ticker, _exchange]} = Company.get_company_info(company_name)
    {:company_market_cap, company_market_cap} = Company.get_company_market_cap_value(company_ticker)
    company_forms_data = Form.get_company_forms_data(company_name, company_market_cap)
    insider_trading_transactions_data = %{
      company_data: %{
        company_name: Map.get(company_name, "company_name", ""),
        company_ticker: company_ticker,
        company_cik: company_cik,
        company_market_cap: company_market_cap
      },
      company_forms_data: company_forms_data
    }
    %{insider_trading_transactions_data: insider_trading_transactions_data}
  end
end
