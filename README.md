# usa-spending-scraper
Code in here uses R to scrape http://USASpending.gov for county-level federal spending information. The aPI v2 for USASpending.gov is very poorly documented, and so this script attempts to make it a little easier by preserving one method for interacting with the API.

Apologies for not building functions to make this a little more portable.

Documentation for the reults of this API call is here: https://github.com/fedspendingtransparency/usaspending-api/blob/dev/usaspending_api/api_docs/api_documentation/advanced_award_search/spending_by_geography.md

You can test API calls, though it will potentially throw errors with parameter specifications that are perfectly valid (and successful) when submitted via POST() functions in R. Endpoint testing here: https://api.usaspending.gov/api/v2/search/spending_by_geography/
