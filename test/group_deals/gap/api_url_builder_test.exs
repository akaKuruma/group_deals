defmodule GroupDeals.Gap.ApiUrlBuilderTest do
  use GroupDeals.DataCase
  alias GroupDeals.Gap.ApiUrlBuilder
  alias GroupDeals.Gap.GapPage

  describe "build_api_url/1" do
    test "builds the api url from the gap page changeset" do
      web_page_url = "https://www.gapfactory.com/browse/women/logo-shop?cid=1111149&nav=meganav%3AWomen%3AFeatured%20Shops%3ALogo%20Shop#pageId=0&department=136"
      gap_page = %GapPage{} |> GapPage.changeset(%{web_page_url: web_page_url})

      api_url = ApiUrlBuilder.build_api_url(gap_page)
      api_url_parsed = URI.parse(api_url)
      query_params = URI.decode_query(api_url_parsed.query)

      assert api_url_parsed.host == "api.gapfactory.com"
      assert api_url_parsed.path == "/commerce/search/products/v2/cc"
      assert Map.equal?(query_params, %{
        "cid" => "1111149",
        "pageSize" => "200",
        "pageNumber" => "0",
        "ignoreInventory" => "false",
        "vendor" => "constructorio",
        "client_id" => "0",
        "session_id" => "0",
        "includeMarketingFlagsDetails" => "true",
        "enableDynamicPhoto" => "true",
        "brand" => "gapfs",
        "locale" => "en_US",
        "market" => "us",
        "department" => "136"
      })
    end
  end
end
