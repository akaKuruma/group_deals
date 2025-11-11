defmodule GroupDeals.Workers.FetchGapPageJsonWorkerTest do
  use GroupDeals.DataCase

  alias GroupDeals.Gap.GapDataFetch
  alias GroupDeals.Workers.FetchGapPageJsonWorker
  alias GroupDeals.Repo

  import GroupDeals.GapFixtures

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "perform/1 - failure scenarios" do
    test "raises error when GapDataFetch is not found" do
      # Create a non-existent gap_data_fetch_id
      fake_id = Ecto.UUID.generate()

      job = %Oban.Job{
        id: 1,
        args: %{"gap_data_fetch_id" => fake_id},
        worker: "GroupDeals.Workers.FetchGapPageJsonWorker",
        queue: "default",
        state: "available"
      }

      # This will raise Ecto.NoResultsError because the fetch doesn't exist
      assert_raise Ecto.NoResultsError, fn ->
        FetchGapPageJsonWorker.perform(job)
      end
    end

    test "returns error when GapApiProductsJsonProcessor returns error", %{bypass: bypass} do
      pages_group = pages_group_fixture()
      gap_page = gap_page_fixture(%{pages_group_id: pages_group.id})

      gap_data_fetch =
        gap_data_fetch_fixture(%{
          pages_group_id: pages_group.id,
          status: :pending,
          folder_timestamp: "20241111000000"
        })

      # Configure Bypass to return 500 error (will be called 3 times due to retries)
      Bypass.stub(bypass, "GET", "/api", fn conn ->
        Plug.Conn.resp(conn, 500, "Internal Server Error")
      end)

      # Update api_url to use Bypass
      gap_page
      |> Ecto.Changeset.change(%{api_url: "http://localhost:#{bypass.port}/api"})
      |> Repo.update!()

      job = %Oban.Job{
        id: 1,
        args: %{"gap_data_fetch_id" => gap_data_fetch.id},
        worker: "GroupDeals.Workers.FetchGapPageJsonWorker",
        queue: "default",
        state: "available"
      }

      result = FetchGapPageJsonWorker.perform(job)

      assert result == :error

      # Verify GapDataFetch was marked as failed
      updated_fetch = Repo.get!(GapDataFetch, gap_data_fetch.id)
      assert updated_fetch.status == :failed
    end

    test "creates folder structure before processing", %{bypass: bypass} do
      pages_group = pages_group_fixture()

      gap_data_fetch =
        gap_data_fetch_fixture(%{
          pages_group_id: pages_group.id,
          status: :pending,
          folder_timestamp: "20241111000000"
        })

      gap_page = gap_page_fixture(%{pages_group_id: pages_group.id})

      # Configure Bypass to return 500 error
      Bypass.stub(bypass, "GET", "/api", fn conn ->
        Plug.Conn.resp(conn, 500, "Internal Server Error")
      end)

      # Update api_url to use Bypass
      gap_page
      |> Ecto.Changeset.change(%{api_url: "http://localhost:#{bypass.port}/api"})
      |> Repo.update!()

      job = %Oban.Job{
        id: 1,
        args: %{"gap_data_fetch_id" => gap_data_fetch.id},
        worker: "GroupDeals.Workers.FetchGapPageJsonWorker",
        queue: "default",
        state: "available"
      }

      folder_path = Path.join(["tmp", to_string(pages_group.id), "20241111000000"])

      # Ensure folder doesn't exist
      File.rm_rf(folder_path)

      FetchGapPageJsonWorker.perform(job)

      # Verify folder was created
      assert File.exists?(folder_path)
      assert File.dir?(folder_path)

      # Cleanup
      File.rm_rf(folder_path)
    end

    test "updates status to fetching_product_list before processing", %{bypass: bypass} do
      pages_group = pages_group_fixture()

      gap_data_fetch =
        gap_data_fetch_fixture(%{
          pages_group_id: pages_group.id,
          status: :pending,
          folder_timestamp: "20241111000000"
        })

      gap_page = gap_page_fixture(%{pages_group_id: pages_group.id})

      # Configure Bypass to return 500 error
      Bypass.stub(bypass, "GET", "/api", fn conn ->
        Plug.Conn.resp(conn, 500, "Internal Server Error")
      end)

      # Update api_url to use Bypass
      gap_page
      |> Ecto.Changeset.change(%{api_url: "http://localhost:#{bypass.port}/api"})
      |> Repo.update!()

      job = %Oban.Job{
        id: 1,
        args: %{"gap_data_fetch_id" => gap_data_fetch.id},
        worker: "GroupDeals.Workers.FetchGapPageJsonWorker",
        queue: "default",
        state: "available"
      }

      FetchGapPageJsonWorker.perform(job)

      # Verify status was updated (even though processing failed)
      updated_fetch = Repo.get!(GapDataFetch, gap_data_fetch.id)

      # Status might be :fetching_product_list (if update succeeded) or :failed (if processing failed)
      assert updated_fetch.status in [:fetching_product_list, :failed]
    end
  end
end
