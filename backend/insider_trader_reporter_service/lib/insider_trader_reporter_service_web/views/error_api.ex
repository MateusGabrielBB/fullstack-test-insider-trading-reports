defmodule InsiderTraderReporterServiceWeb.ErrorApi do

  def render("404.json", _) do
    %{
      error: %{
        type: "Not Found Error",
        message: "Resource not found!",
      }
    }
  end

  def render("500.json", %{message: message}) do
    %{
      error: %{
        type: "Internal Server Error",
        message: "Sorry for the inconvenience, but an unexpected error has occurred! | Message #{message}",
      }
    }
  end

  def render("500.json", _) do
    %{
      error: %{
        type: "Internal Server Error",
        message: "Sorry for the inconvenience, but an unexpected error has occurred!",
      }
    }
  end

  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
