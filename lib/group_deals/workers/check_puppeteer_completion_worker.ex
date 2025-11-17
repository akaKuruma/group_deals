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
    case Gap.check_page_fetch_completion(gap_data_fetch_id) do
      %{pending: 0} = stats ->
        # All done! Schedule parsing jobs
        Logger.info("All pages downloaded for fetch #{gap_data_fetch_id}: #{inspect(stats)}")
        schedule_parsing_jobs(gap_data_fetch_id, id_store_category)
        :ok

      %{pending: pending} when pending > 0 ->
        # Still pending, reschedule this job
        Logger.info("Still #{pending} pages pending for fetch #{gap_data_fetch_id}")
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
