defmodule InsiderTraderReporterService.Clients.ClientHelper do
  def handle_client_response(client_response) do
    case client_response do
      {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} ->
        {:ok, resp_body}

      {:ok, %HTTPoison.Response{status_code: code, body: _resp_body}} when code !== 200 ->
        {:error, "Failed request! | Response Status code: #{code}"}

      {:error, reason} ->
        {:error, "Failed request! | Reason: #{reason}"}

      _ ->
        {:error, "Failed request! | Unknown Reason"}
    end
  end
end
