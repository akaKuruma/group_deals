defmodule GroupDeals.Workers.FetchGapPageJsonWorker do
  @moduledoc """
  Oban worker that fetches product data from Gap API for each GapPage.

  This is the first job in the workflow. It:
  1. Creates the folder structure
  2. Updates status to :fetching_product_list
  3. Fetches JSON from Gap API for each GapPage (sequentially)
  4. Stores products and schedules the next job
  """

  alias GroupDeals.Gap.FetchCoordinator
  alias GroupDeals.Gap
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"gap_data_fetch_id" => gap_data_fetch_id}}) do
    gap_data_fetch = Gap.get_active_gap_data_fetch!(gap_data_fetch_id)
    # TODO: Implement Job 1 logic
    # 1. Get GapDataFetch and PagesGroup
    # 2. Create folder: tmp/{pages_group_id}/{folder_timestamp}/
    # 3. Update status to :fetching_product_list
    # 4. For each GapPage, fetch API and process products
    # 5. Schedule next job when complete

    # -- START REMOVE --
    FetchCoordinator.finish_fetch(gap_data_fetch, %{status: :succeeded})
    # -- END REMOVE --

    {:ok, :not_implemented_yet}
  end
end
