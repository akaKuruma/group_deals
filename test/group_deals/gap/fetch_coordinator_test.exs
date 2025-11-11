defmodule GroupDeals.Gap.FetchCoordinatorTest do
  use GroupDeals.DataCase

  alias GroupDeals.Gap.FetchCoordinator
  alias GroupDeals.Gap.GapDataFetch

  import GroupDeals.GapFixtures

  describe "start_fetch/1" do
    test "creates a gap_data_fetch and schedules job when no active fetch exists" do
      pages_group = pages_group_fixture()

      assert {:ok, %GapDataFetch{} = gap_data_fetch} = FetchCoordinator.start_fetch(pages_group)

      assert gap_data_fetch.pages_group_id == pages_group.id
      assert gap_data_fetch.status == :pending
      assert is_binary(gap_data_fetch.folder_timestamp)
      assert String.length(gap_data_fetch.folder_timestamp) == 14

      # Verify job was scheduled by checking Oban jobs table
      import Ecto.Query
      alias GroupDeals.Repo

      job =
        from(j in Oban.Job,
          where: j.worker == "GroupDeals.Workers.FetchGapPageJsonWorker",
          order_by: [desc: j.inserted_at],
          limit: 1
        )
        |> Repo.one()

      assert job != nil
      assert job.args["gap_data_fetch_id"] == gap_data_fetch.id
    end

    test "returns error when active fetch exists" do
      pages_group = pages_group_fixture()
      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :pending})

      assert {:error, :active_fetch_exists} = FetchCoordinator.start_fetch(pages_group)
    end

    test "returns error when running fetch exists" do
      pages_group = pages_group_fixture()
      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :fetching_product_list})

      assert {:error, :active_fetch_exists} = FetchCoordinator.start_fetch(pages_group)
    end

    test "allows new fetch when previous fetch is failed" do
      pages_group = pages_group_fixture()
      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :failed})

      assert {:ok, %GapDataFetch{}} = FetchCoordinator.start_fetch(pages_group)
    end

    test "allows new fetch when previous fetch is succeeded" do
      pages_group = pages_group_fixture()
      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :succeeded})

      assert {:ok, %GapDataFetch{}} = FetchCoordinator.start_fetch(pages_group)
    end

    test "generates timestamp in correct format" do
      pages_group = pages_group_fixture()

      assert {:ok, %GapDataFetch{} = gap_data_fetch} = FetchCoordinator.start_fetch(pages_group)

      timestamp = gap_data_fetch.folder_timestamp
      assert String.length(timestamp) == 14
      assert String.match?(timestamp, ~r/^\d{14}$/)
    end

    test "stores timestamp in gap_data_fetch" do
      pages_group = pages_group_fixture()

      assert {:ok, %GapDataFetch{} = gap_data_fetch} = FetchCoordinator.start_fetch(pages_group)

      assert gap_data_fetch.folder_timestamp != nil
      assert is_binary(gap_data_fetch.folder_timestamp)
    end
  end
end
