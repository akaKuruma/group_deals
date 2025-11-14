defmodule GroupDeals.Workers.FetchProductPagesWorker do
  @moduledoc """
  Oban worker that fetches HTML product pages for each ProductData.

  This is the second job in the workflow. It:
  1. Updates status to :fetching_product_page
  2. Fetches HTML from product pages for each ProductData (sequentially)
  3. Saves HTML files to disk
  4. Updates ProductData records with file paths
  5. Schedules the next job (ParseProductPagesWorker)
  """

  alias GroupDeals.Gap
  alias GroupDeals.Gap.GapProductPagesHandler
  alias Oban
  require Logger

  use Oban.Worker, queue: :fetch_product_html_page

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"gap_data_fetch_id" => gap_data_fetch_id}}) do
    gap_data_fetch = Gap.get_active_gap_data_fetch!(gap_data_fetch_id)
    pages_group = gap_data_fetch.pages_group

    # Get first GapPage for URL parameters (all products share same category context)
    gap_page = get_first_gap_page(pages_group.gap_pages)

    # 1. Update status to :fetching_product_page
    case Gap.update_gap_data_fetch(gap_data_fetch, %{
           status: :fetching_product_page
         }) do
      {:ok, updated_fetch} ->
        # 2. Process all products
        case process_all_products(updated_fetch, gap_data_fetch_id, gap_page, pages_group.id) do
          {:ok, _count} ->
            # All products processed successfully, schedule next job
            schedule_next_job(gap_data_fetch.id)
            :ok

          {:error, reason} ->
            if Mix.env() != :test,
              do: Logger.error("Failed to process products: #{inspect(reason)}")

            mark_as_failed(gap_data_fetch, "Failed to process products: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, changeset} ->
        if Mix.env() != :test,
          do: Logger.error("Failed to update GapDataFetch status: #{inspect(changeset)}")

        mark_as_failed(gap_data_fetch, "Failed to update status")
        {:error, Gap.traverse_changeset_errors(changeset)}
    end
  end

  defp get_first_gap_page([]), do: nil
  defp get_first_gap_page([gap_page | _]), do: gap_page

  defp process_all_products(gap_data_fetch, gap_data_fetch_id, gap_page, pages_group_id) do
    # Get all ProductData records for this fetch
    product_data_list = Gap.list_gap_product_data_for_fetch(gap_data_fetch_id)

    # Set total_products if not already set
    updated_fetch =
      if gap_data_fetch.total_products == 0 do
        case Gap.update_gap_data_fetch(gap_data_fetch, %{
               total_products: length(product_data_list)
             }) do
          {:ok, fetch} -> fetch
          {:error, _} -> gap_data_fetch
        end
      else
        gap_data_fetch
      end

    # Process each ProductData sequentially
    GapProductPagesHandler.process_products(
      updated_fetch,
      product_data_list,
      gap_page,
      pages_group_id
    )
  end

  defp mark_as_failed(gap_data_fetch, error_message) do
    Gap.update_gap_data_fetch(gap_data_fetch, %{
      status: :failed,
      error_message: error_message
    })
  end

  defp schedule_next_job(gap_data_fetch_id) do
    # Schedule Job 3: ParseProductPagesWorker
    # Note: This worker doesn't exist yet, but we'll create a placeholder
    Logger.info(
      "All product pages fetched. Next job (ParseProductPagesWorker) should be scheduled for gap_data_fetch_id: #{gap_data_fetch_id}"
    )

    # TODO: Uncomment when ParseProductPagesWorker is created
    # %{gap_data_fetch_id: gap_data_fetch_id}
    # |> GroupDeals.Workers.ParseProductPagesWorker.new()
    # |> Oban.insert()
  end
end
