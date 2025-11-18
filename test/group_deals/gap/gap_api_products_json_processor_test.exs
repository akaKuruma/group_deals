defmodule GroupDeals.Gap.GapApiProductsJsonProcessorTest do
  use GroupDeals.DataCase

  alias GroupDeals.Gap
  alias GroupDeals.Gap.GapApiProductsJsonProcessor
  alias GroupDeals.Gap.GapGroupProductsFetchStatus
  alias GroupDeals.Repo

  import GroupDeals.GapFixtures

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "process_pages/3 - failure scenarios" do
    test "returns :error when API fetch fails after retries", %{bypass: bypass} do
      pages_group = pages_group_fixture()

      gap_data_fetch =
        gap_data_fetch_fixture(%{
          pages_group_id: pages_group.id,
          status: :processing,
          product_list_page_total: 1
        })

      gap_page =
        gap_page_fixture(%{
          pages_group_id: pages_group.id
        })

      # Configure Bypass to return 500 error (will be called 3 times due to retries)
      Bypass.stub(bypass, "GET", "/api", fn conn ->
        Plug.Conn.resp(conn, 500, "Internal Server Error")
      end)

      # Update api_url to use Bypass
      gap_page
      |> Ecto.Changeset.change(%{api_url: "http://localhost:#{bypass.port}/api"})
      |> Repo.update!()

      gap_data_fetch = Gap.get_active_gap_group_products_fetch_status!(gap_data_fetch.id)
      # Reload gap_page to get updated api_url
      gap_page = Repo.get!(Gap.GapPage, gap_page.id)
      gap_pages = [gap_page]

      result = GapApiProductsJsonProcessor.process_pages(gap_data_fetch, gap_pages, "tmp/test")

      assert result == :error

      # Verify GapGroupProductsFetchStatus was marked as failed
      updated_fetch = Repo.get!(GapGroupProductsFetchStatus, gap_data_fetch.id)
      assert updated_fetch.status == :failed
      assert updated_fetch.error_message =~ "Failed to process page"
    end

    test "returns :error when API returns invalid JSON", %{bypass: bypass} do
      pages_group = pages_group_fixture()

      gap_data_fetch =
        gap_data_fetch_fixture(%{
          pages_group_id: pages_group.id,
          status: :processing,
          product_list_page_total: 1
        })

      gap_page =
        gap_page_fixture(%{
          pages_group_id: pages_group.id
        })

      # Configure Bypass to return invalid JSON (use stub to allow retries)
      Bypass.stub(bypass, "GET", "/api", fn conn ->
        Plug.Conn.put_resp_content_type(conn, "application/json")
        |> Plug.Conn.resp(200, "invalid json {")
      end)

      # Update api_url to use Bypass
      gap_page
      |> Ecto.Changeset.change(%{api_url: "http://localhost:#{bypass.port}/api"})
      |> Repo.update!()

      gap_data_fetch = Gap.get_active_gap_group_products_fetch_status!(gap_data_fetch.id)
      gap_page = Repo.get!(Gap.GapPage, gap_page.id)
      gap_pages = [gap_page]

      result = GapApiProductsJsonProcessor.process_pages(gap_data_fetch, gap_pages, "tmp/test")

      assert result == :error

      updated_fetch = Repo.get!(GapGroupProductsFetchStatus, gap_data_fetch.id)
      assert updated_fetch.status == :failed
    end

    test "handles empty products array gracefully", %{bypass: bypass} do
      pages_group = pages_group_fixture()

      gap_data_fetch =
        gap_data_fetch_fixture(%{
          pages_group_id: pages_group.id,
          status: :processing,
          product_list_page_total: 1,
          products_total: 0,
          folder_timestamp: "20241111000000"
        })

      gap_page =
        gap_page_fixture(%{
          pages_group_id: pages_group.id
        })

      json_body = %{"products" => []}
      json_string = Jason.encode!(json_body)

      Bypass.stub(bypass, "GET", "/api", fn conn ->
        Plug.Conn.put_resp_content_type(conn, "application/json")
        |> Plug.Conn.resp(200, json_string)
      end)

      # Update api_url to use Bypass
      gap_page
      |> Ecto.Changeset.change(%{api_url: "http://localhost:#{bypass.port}/api"})
      |> Repo.update!()

      # Reload gap_data_fetch to get updated gap_pages
      gap_data_fetch = Gap.get_active_gap_group_products_fetch_status!(gap_data_fetch.id)
      # Reload gap_page to get updated api_url
      gap_page = Repo.get!(Gap.GapPage, gap_page.id)
      # Build gap_pages list with updated gap_page
      gap_pages = [gap_page]

      result = GapApiProductsJsonProcessor.process_pages(gap_data_fetch, gap_pages, "tmp/test")

      assert {:ok, 0} = result

      # Verify GapDataFetch was updated
      updated_fetch = Repo.get!(GapGroupProductsFetchStatus, gap_data_fetch.id)
      assert updated_fetch.product_list_page_succeeded_count == 1
      assert updated_fetch.products_total == 0

      # Verify GapDataFetch was updated
      updated_fetch = Repo.get!(GapGroupProductsFetchStatus, gap_data_fetch.id)
      assert updated_fetch.product_list_page_succeeded_count == 1
      assert updated_fetch.products_total == 0
    end

    test "handles missing products key in JSON", %{bypass: bypass} do
      pages_group = pages_group_fixture()

      gap_data_fetch =
        gap_data_fetch_fixture(%{
          pages_group_id: pages_group.id,
          status: :processing,
          product_list_page_total: 1,
          folder_timestamp: "20241111000000"
        })

      gap_page =
        gap_page_fixture(%{
          pages_group_id: pages_group.id
        })

      json_body = %{"pagination" => %{}, "categories" => []}
      json_string = Jason.encode!(json_body)

      Bypass.stub(bypass, "GET", "/api", fn conn ->
        Plug.Conn.put_resp_content_type(conn, "application/json")
        |> Plug.Conn.resp(200, json_string)
      end)

      # Update api_url to use Bypass
      gap_page
      |> Ecto.Changeset.change(%{api_url: "http://localhost:#{bypass.port}/api"})
      |> Repo.update!()

      # Reload gap_data_fetch to get updated gap_pages
      gap_data_fetch = Gap.get_active_gap_group_products_fetch_status!(gap_data_fetch.id)
      # Reload gap_page to get updated api_url
      gap_page = Repo.get!(Gap.GapPage, gap_page.id)
      # Build gap_pages list with updated gap_page
      gap_pages = [gap_page]

      result = GapApiProductsJsonProcessor.process_pages(gap_data_fetch, gap_pages, "tmp/test")

      assert {:ok, 0} = result

      # Verify GapDataFetch was updated
      updated_fetch = Repo.get!(GapGroupProductsFetchStatus, gap_data_fetch.id)
      assert updated_fetch.product_list_page_succeeded_count == 1
      assert updated_fetch.products_total == 0
    end

    test "handles products with missing styleColors", %{bypass: bypass} do
      pages_group = pages_group_fixture()

      gap_data_fetch =
        gap_data_fetch_fixture(%{
          pages_group_id: pages_group.id,
          status: :processing,
          product_list_page_total: 1,
          folder_timestamp: "20241111000000"
        })

      gap_page =
        gap_page_fixture(%{
          pages_group_id: pages_group.id
        })

      json_body = %{
        "products" => [
          %{
            "styleId" => "123",
            "styleName" => "Test Product"
            # Missing styleColors
          }
        ]
      }

      json_string = Jason.encode!(json_body)

      Bypass.stub(bypass, "GET", "/api", fn conn ->
        Plug.Conn.put_resp_content_type(conn, "application/json")
        |> Plug.Conn.resp(200, json_string)
      end)

      # Update api_url to use Bypass
      gap_page
      |> Ecto.Changeset.change(%{api_url: "http://localhost:#{bypass.port}/api"})
      |> Repo.update!()

      # Reload gap_data_fetch to get updated gap_pages
      gap_data_fetch = Gap.get_active_gap_group_products_fetch_status!(gap_data_fetch.id)
      # Reload gap_page to get updated api_url
      gap_page = Repo.get!(Gap.GapPage, gap_page.id)
      # Build gap_pages list with updated gap_page
      gap_pages = [gap_page]

      result = GapApiProductsJsonProcessor.process_pages(gap_data_fetch, gap_pages, "tmp/test")

      assert {:ok, 0} = result

      # Verify GapDataFetch was updated
      updated_fetch = Repo.get!(GapGroupProductsFetchStatus, gap_data_fetch.id)
      assert updated_fetch.product_list_page_succeeded_count == 1
      assert updated_fetch.products_total == 0
    end

    test "continues processing when GapProductData creation fails due to missing folder_timestamp",
         %{bypass: bypass} do
      pages_group = pages_group_fixture()

      gap_data_fetch =
        gap_data_fetch_fixture(%{
          pages_group_id: pages_group.id,
          status: :processing,
          product_list_page_total: 1,
          # This will cause validation failure
          folder_timestamp: nil
        })

      gap_page =
        gap_page_fixture(%{
          pages_group_id: pages_group.id
        })

      json_body = %{
        "products" => [
          %{
            "styleId" => "123",
            "styleName" => "Test Product",
            "styleColors" => [
              %{
                "ccId" => "456",
                "ccName" => "Red",
                "images" => []
              }
            ]
          }
        ]
      }

      json_string = Jason.encode!(json_body)

      Bypass.stub(bypass, "GET", "/api", fn conn ->
        Plug.Conn.put_resp_content_type(conn, "application/json")
        |> Plug.Conn.resp(200, json_string)
      end)

      # Update api_url to use Bypass
      gap_page
      |> Ecto.Changeset.change(%{api_url: "http://localhost:#{bypass.port}/api"})
      |> Repo.update!()

      gap_data_fetch = Gap.get_active_gap_group_products_fetch_status!(gap_data_fetch.id)
      gap_page = Repo.get!(Gap.GapPage, gap_page.id)
      gap_pages = [gap_page]

      result = GapApiProductsJsonProcessor.process_pages(gap_data_fetch, gap_pages, "tmp/test")

      # Process should continue even when GapProductData creation fails
      # It will return {:ok, 0} because no products were successfully created
      assert {:ok, 0} = result

      # Verify GapGroupProductsFetchStatus was updated (product_list_page_succeeded_count incremented)
      updated_fetch = Repo.get!(GapGroupProductsFetchStatus, gap_data_fetch.id)
      assert updated_fetch.product_list_page_succeeded_count == 1
      assert updated_fetch.products_total == 0
      # Status should still be :processing, not :failed
      assert updated_fetch.status == :processing
    end
  end
end
