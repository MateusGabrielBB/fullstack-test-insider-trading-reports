defmodule InsiderTraderReporterService.InsiderTrader do
  defstruct [
      insider_name: "",
      insider_title: ""
  ]

  def new(insider_name, insider_title) do
    %InsiderTraderReporterService.InsiderTrader{
      insider_name: insider_name,
      insider_title: insider_title
    }
  end
end
