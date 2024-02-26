# fullstack-test-insider-trading-reports
This is a WIP!

# How to run the server
First make sure you'r inside the directory `/backend/insider_trader_reporter_service/` then run the commands:
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

# How to use the API
To get the insider trading transactions data, you need to make a request to the endpoint `http://localhost:4000/api/company/{company_name}/insider-trading-data`.
Currently, to get a response from the API, the path parameter `{company_name}` must be equal to the company names in this [file](https://www.sec.gov/files/company_tickers_exchange.json) (in the file the field is called `"name"`).

If the request have a valid company name, the response should be something like:
```
{
    "insider_trading_transactions_data": {
        "company_data": {
            "company_market_cap": 3058740494336,
            "company_cik": 789019,
            "company_name": "MICROSOFT CORP",
            "company_ticker": "MSFT"
        },
        "company_filings_data": [
            {
                "transaction_data": {
                    "insider_name": "SMITH BRADFORD L",
                    "insider_title": "Vice Chair and President",
                    "filing_url": "https://www.sec.gov/Archives/edgar/data/789019/000106299324002112/form4.xml",
                    "market_cap_percentage_value": "0.000607740%",
                    "transaction_date": "2024-02-02",
                    "transaction_per_share_price": 411.7784,
                    "transaction_shares_amount": 45000,
                    "transaction_value": 18530028.0
                }
            },
            {
                "transaction_data": {
                    "insider_name": "SMITH BRADFORD L",
                    "insider_title": "Vice Chair and President",
                    "filing_url": "https://www.sec.gov/Archives/edgar/data/789019/000106299324002112/form4.xml",
                    "market_cap_percentage_value": "0.000014315%",
                    "transaction_date": "2024-02-05",
                    "transaction_per_share_price": 404.8921,
                    "transaction_shares_amount": 1078,
                    "transaction_value": 436473.68380000006
                }
            },
            ...
        ]
    }
}
```

# Future improvements:
- ~~Fix XML parser that causes inconsistencies when linking the number of shares sold and the value per share used in the transaction~~
- Get the market values from the same data as the transactions to have a more accurate `market_cap_percentage_value`
- Refactor the code to make it more readable and easier to work on the others improvements
- React frontend to make easier to search and analyze the data
- Virtualize the development environment with docker and docker-compose
- Improve the search to find the company data without having an exact match
- Add some kind of cache to avoid repeated requests for no reason, also add a validation of cached data to confirm when new requests are necessary
- Unit and integration tests
- API and project documentation
