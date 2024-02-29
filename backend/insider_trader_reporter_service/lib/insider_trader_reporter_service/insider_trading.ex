defmodule InsiderTraderReporterService.InsiderTrading do
  alias InsiderTraderReporterService.Company
  alias InsiderTraderReporterService.Form

  @derive(Jason.Encoder)
  defstruct [
    company_data: %Company{},
    company_forms_data: %Form{}
  ]

  defp new(company_data, company_forms_data) do
    %InsiderTraderReporterService.InsiderTrading{
      company_data: company_data,
      company_forms_data: company_forms_data
    }
  end

  def get_insider_trading_report_data(company_name) do
    {:company_data, company_data} = Company.get_company_data(company_name)
    company_forms_data = Form.get_company_forms_data(company_name, company_data.company_ticker)
    insider_trading_transactions_data = new(company_data, company_forms_data)
    %{insider_trading_transactions_data: insider_trading_transactions_data}
  end
end
