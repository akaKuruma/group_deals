defmodule GroupDeals.Workers.CheckPuppeteerCompletionWorker do
  @moduledoc """
  Polls the database to check if Puppeteer script has finished downloading all pages.
  """

  alias GroupDeals.Gap
  alias GroupDeals.Workers.ParseProductPagesWorker
  alias Oban
  require Logger

  use Oban.Worker, queue: :fetch_product_html_page, max_attempts: 200

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "gap_data_fetch_id" => gap_data_fetch_id,
          "id_store_category" => id_store_category
        }
      }) do
    # Get the fetch status record
    gap_group_products_fetch_status =
      Gap.get_active_gap_group_products_fetch_status!(gap_data_fetch_id)

    case Gap.check_page_fetch_completion(gap_data_fetch_id) do
      %{pending: 0} = stats ->
        # All done! Update fetch status and schedule parsing jobs
        Logger.info("All pages downloaded for fetch #{gap_data_fetch_id}: #{inspect(stats)}")

        # Update product_page_fetched_count to reflect completed fetches (succeeded + failed)
        total_fetched = stats.succeeded + stats.failed

        case Gap.update_gap_group_products_fetch_status(gap_group_products_fetch_status, %{
               product_page_fetched_count: total_fetched
             }) do
          {:ok, _updated} ->
            schedule_parsing_jobs(gap_data_fetch_id, id_store_category)
            :ok

          {:error, changeset} ->
            Logger.error("Failed to update GapGroupProductsFetchStatus: #{inspect(changeset)}")
            :error
        end

      %{pending: pending, succeeded: succeeded, failed: failed} when pending > 0 ->
        # Still pending, but update progress counter to reflect current completed count
        total_fetched = succeeded + failed

        # Only update if the count has changed to avoid unnecessary database writes
        if gap_group_products_fetch_status.product_page_fetched_count != total_fetched do
          case Gap.update_gap_group_products_fetch_status(gap_group_products_fetch_status, %{
                 product_page_fetched_count: total_fetched
               }) do
            {:ok, _updated} ->
              Logger.info(
                "Still #{pending} pages pending for fetch #{gap_data_fetch_id}, #{total_fetched} completed"
              )

            {:error, changeset} ->
              Logger.warning("Failed to update progress counter: #{inspect(changeset)}")
          end
        else
          Logger.info("Still #{pending} pages pending for fetch #{gap_data_fetch_id}")
        end

        schedule_next_check(gap_data_fetch_id, id_store_category)
        :ok

      _ ->
        Logger.warning("No product data found for fetch #{gap_data_fetch_id}")
        :ok
    end
  end

  defp schedule_next_check(gap_data_fetch_id, id_store_category) do
    %{"gap_data_fetch_id" => gap_data_fetch_id, "id_store_category" => id_store_category}
    # Check again in 60 seconds
    |> new(schedule_in: 60)
    |> Oban.insert()
  end

  defp schedule_parsing_jobs(gap_data_fetch_id, id_store_category) do
    # Get all succeeded product data records and schedule parsing
    product_data_list = Gap.list_gap_product_data_for_fetch(gap_data_fetch_id)

    Enum.each(product_data_list, fn product_data ->
      if product_data.page_fetch_status == :succeeded && product_data.html_file_path do
        %{
          gap_data_fetch_id: gap_data_fetch_id,
          product_data_id: product_data.id,
          id_store_category: id_store_category
        }
        |> ParseProductPagesWorker.new()
        |> Oban.insert()
      end
    end)
  end
end
