defmodule GroupDeals.Gap.ProductUrlBuilderTest do
  use ExUnit.Case

  alias GroupDeals.Gap.ProductUrlBuilder
  alias GroupDeals.Gap.GapPage

  describe "build_product_url/2" do
    test "builds full URL with all parameters from GapPage" do
      gap_page = %GapPage{
        web_page_parameters: %{
          "vid" => "1",
          "pcid" => "1111149",
          "cid" => "1111149",
          "nav" => "meganav:Women:Featured Shops:Logo Shop"
        }
      }

      url = ProductUrlBuilder.build_product_url("814031011", gap_page)

      assert url ==
               "https://www.gapfactory.com/browse/product.do?pid=814031011&vid=1&pcid=1111149&cid=1111149&nav=meganav%3AWomen%3AFeatured+Shops%3ALogo+Shop#pdp-page-content"
    end

    test "builds URL with minimal parameters when only cid is available" do
      gap_page = %GapPage{
        web_page_parameters: %{
          "cid" => "1111149"
        }
      }

      url = ProductUrlBuilder.build_product_url("814031011", gap_page)

      assert url ==
               "https://www.gapfactory.com/browse/product.do?pid=814031011&vid=1&pcid=1111149&cid=1111149#pdp-page-content"
    end

    test "uses pcid as fallback for cid when cid is missing" do
      gap_page = %GapPage{
        web_page_parameters: %{
          "pcid" => "1111149"
        }
      }

      url = ProductUrlBuilder.build_product_url("814031011", gap_page)

      assert url ==
               "https://www.gapfactory.com/browse/product.do?pid=814031011&vid=1&pcid=1111149&cid=1111149#pdp-page-content"
    end

    test "builds minimal URL when GapPage has no parameters" do
      gap_page = %GapPage{web_page_parameters: nil}

      url = ProductUrlBuilder.build_product_url("814031011", gap_page)

      assert url == "https://www.gapfactory.com/browse/product.do?pid=814031011"
    end

    test "builds minimal URL when GapPage has empty parameters" do
      gap_page = %GapPage{web_page_parameters: %{}}

      url = ProductUrlBuilder.build_product_url("814031011", gap_page)

      assert url == "https://www.gapfactory.com/browse/product.do?pid=814031011"
    end

    test "handles atom keys in web_page_parameters" do
      gap_page = %GapPage{
        web_page_parameters: %{
          vid: "1",
          cid: "1111149"
        }
      }

      url = ProductUrlBuilder.build_product_url("814031011", gap_page)

      assert url ==
               "https://www.gapfactory.com/browse/product.do?pid=814031011&vid=1&pcid=1111149&cid=1111149#pdp-page-content"
    end

    test "URL encodes nav parameter correctly" do
      gap_page = %GapPage{
        web_page_parameters: %{
          "cid" => "1111149",
          "nav" => "meganav:Women:Featured Shops:Logo Shop"
        }
      }

      url = ProductUrlBuilder.build_product_url("814031011", gap_page)

      # Verify URL encoding: : becomes %3A, space becomes +
      assert String.contains?(url, "nav=meganav%3AWomen%3AFeatured+Shops%3ALogo+Shop")
    end

    test "defaults vid to 1 when not provided" do
      gap_page = %GapPage{
        web_page_parameters: %{
          "cid" => "1111149"
        }
      }

      url = ProductUrlBuilder.build_product_url("814031011", gap_page)

      assert String.contains?(url, "vid=1")
    end
  end
end
