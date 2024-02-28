defmodule InsiderTraderReporterService.InsiderTrader do
  @derive(Jason.Encoder)
  defstruct [
      insider_name: "",
      insider_title: ""
  ]

  defp new(insider_name, insider_title) do
    %InsiderTraderReporterService.InsiderTrader{
      insider_name: insider_name,
      insider_title: insider_title
    }
  end

  def get_insider_trader_data(company_form_data) do
    insider_data = company_form_data
    |> Map.get("reportingOwner", %{})
    insider_name = insider_data
    |> Map.get("reportingOwnerId", %{})
    |> Map.get("rptOwnerName", "")
    insider_title = insider_data
    |> Map.get("reportingOwnerRelationship", %{})
    |> Map.get("officerTitle", "")
    new(insider_name, insider_title)
  end
end
