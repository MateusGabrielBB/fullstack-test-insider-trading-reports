defmodule InsiderTraderReporterServiceWeb.FallbackController do
  use InsiderTraderReporterServiceWeb, :controller

  alias InsiderTraderReporterServiceWeb.ErrorApi

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorApi)
    |> render(:"404")
  end

  def call(conn, {:error, message}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(ErrorApi)
    |> render(:"500", message: message)
  end
end
