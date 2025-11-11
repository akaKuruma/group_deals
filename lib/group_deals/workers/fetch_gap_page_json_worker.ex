defmodule GroupDeals.Workers.FetchGapPageJsonWorker do
  @moduledoc """
  Oban worker that fetches product data from Gap API for each GapPage.

  This is the first job in the workflow. It:
  1. Creates the folder structure
  2. Updates status to :fetching_product_list
  3. Fetches JSON from Gap API for each GapPage (sequentially)
  4. Stores products and schedules the next job
  """

  alias GroupDeals.Gap
  alias GroupDeals.Gap.GapApiProductsJsonProcessor
  alias Oban
  require Logger

  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"gap_data_fetch_id" => gap_data_fetch_id}}) do
    gap_data_fetch = Gap.get_active_gap_data_fetch!(gap_data_fetch_id)
    pages_group = gap_data_fetch.pages_group
    gap_pages = pages_group.gap_pages

    # 1. Create folder structure
    folder_path = create_folder(pages_group.id, gap_data_fetch.folder_timestamp)

    # 2. Update status to :fetching_product_list
    case Gap.update_gap_data_fetch(gap_data_fetch, %{
           status: :fetching_product_list,
           started_at: DateTime.utc_now(),
           total_pages: length(gap_pages)
         }) do
      {:ok, updated_fetch} ->
        # 3. Process each GapPage sequentially
        case GapApiProductsJsonProcessor.process_pages(updated_fetch, gap_pages, folder_path) do
          {:ok, _count} ->
            # All pages processed successfully, schedule next job
            schedule_next_job(gap_data_fetch.id)
            :ok

          :error ->
            :error
        end

      {:error, changeset} ->
        Logger.error("Failed to update GapDataFetch status: #{inspect(changeset)}")
        mark_as_failed(gap_data_fetch, "Failed to update status")
    end
  end

  defp mark_as_failed(gap_data_fetch, error_message) do
    Gap.update_gap_data_fetch(gap_data_fetch, %{
      status: :failed,
      error_message: error_message
    })
  end

  defp create_folder(pages_group_id, folder_timestamp) do
    folder_path = Path.join(["tmp", to_string(pages_group_id), folder_timestamp])
    File.mkdir_p!(folder_path)
    folder_path
  end

  defp schedule_next_job(gap_data_fetch_id) do
    # Schedule Job 2: FetchProductPagesWorker
    # Note: This worker doesn't exist yet, but we'll create a placeholder
    # For now, we'll just log that it should be scheduled
    Logger.info(
      "All pages processed. Next job (FetchProductPagesWorker) should be scheduled for gap_data_fetch_id: #{gap_data_fetch_id}"
    )

    # TODO: Uncomment when FetchProductPagesWorker is created
    # %{gap_data_fetch_id: gap_data_fetch_id}
    # |> GroupDeals.Workers.FetchProductPagesWorker.new()
    # |> Oban.insert()
  end
end
