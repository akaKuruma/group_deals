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

  use Oban.Worker, queue: :fetch_group_products_json

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"gap_data_fetch_id" => gap_data_fetch_id}}) do
    gap_group_products_fetch_status =
      Gap.get_active_gap_group_products_fetch_status!(gap_data_fetch_id)

    pages_group = gap_group_products_fetch_status.pages_group
    gap_pages = pages_group.gap_pages

    # 1. Create folder structure
    folder_path = create_folder(pages_group.id, gap_group_products_fetch_status.folder_timestamp)

    # 2. Update status to :processing
    case Gap.update_gap_group_products_fetch_status(gap_group_products_fetch_status, %{
           status: :processing,
           started_at: DateTime.utc_now(),
           product_list_page_total: length(gap_pages)
         }) do
      {:ok, updated_fetch} ->
        # 3. Process each GapPage sequentially
        case GapApiProductsJsonProcessor.process_pages(updated_fetch, gap_pages, folder_path) do
          {:ok, _count} ->
            # All pages processed successfully, schedule next job
            schedule_next_job(gap_group_products_fetch_status.id)
            :ok

          {:error, reason} ->
            {:error, reason}
        end

      {:error, changeset} ->
        Logger.error("Failed to update GapGroupProductsFetchStatus status: #{inspect(changeset)}")
        mark_as_failed(gap_group_products_fetch_status, "Failed to update status")
        {:error, :status_update_failed}
    end
  end

  defp mark_as_failed(gap_group_products_fetch_status, error_message) do
    Gap.update_gap_group_products_fetch_status(gap_group_products_fetch_status, %{
      status: :failed,
      error_message: error_message
    })
  end

  defp create_folder(pages_group_id, folder_timestamp) do
    folder_path = Path.join(["/tmp/gap_site", pages_group_id, folder_timestamp])
    File.mkdir_p!(folder_path)
    folder_path
  end

  defp schedule_next_job(gap_data_fetch_id) do
    # Schedule Job 2: FetchProductPagesWorker
    %{gap_data_fetch_id: gap_data_fetch_id}
    |> GroupDeals.Workers.FetchProductPagesWorker.new()
    |> Oban.insert()
  end
end
