defmodule GroupDeals.Workers.ParseProductPagesWorker do
  @moduledoc """
  Oban worker that parses HTML product pages to extract product data.

  This is the third job in the workflow. It:
  1. Reads HTML from ProductData.html_file_path
  2. Parses HTML to extract sizes, image_url, description, price
  3. Updates ProductData.parsed_data with extracted information

  Each job processes a single ProductData record (can run in parallel).
  """

  alias GroupDeals.Gap
  alias GroupDeals.Gap.GapHtmlParser
  alias Oban
  require Logger

  use Oban.Worker, queue: :parse_product_html_page

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "gap_data_fetch_id" => gap_data_fetch_id,
          "product_data_id" => product_data_id,
          "id_store_category" => id_store_category
        }
      }) do
    # Verify the fetch is still active
    _gap_data_fetch = Gap.get_active_gap_data_fetch!(gap_data_fetch_id)

    try do
      product_data = Gap.get_gap_product_data!(product_data_id)

      if product_data.gap_data_fetch_id != gap_data_fetch_id do
        Logger.error(
          "ProductData #{product_data_id} does not belong to GapDataFetch #{gap_data_fetch_id}"
        )
        {:error, :mismatched_fetch}
      else
        parse_product_page(product_data, id_store_category)
      end
    rescue
      Ecto.NoResultsError ->
        Logger.error("ProductData not found: #{product_data_id}")
        {:error, :product_data_not_found}
    end
  end

  defp parse_product_page(product_data, id_store_category) do
    if is_nil(product_data.html_file_path) do
      Logger.error("ProductData #{product_data.id} has no html_file_path")
      {:error, :missing_html_file_path}
    else
      case File.read(product_data.html_file_path) do
        {:ok, html} ->
          # Parse HTML and extract product data (including discount calculation from marketing_flag)
          parsed_data = GapHtmlParser.parse_html(html, id_store_category, product_data.marketing_flag)

          # Update ProductData with parsed data
          case Gap.update_gap_product_data(product_data, %{parsed_data: parsed_data}) do
            {:ok, _updated} ->
              :ok

            {:error, changeset} ->
              Logger.error("Failed to update ProductData: #{inspect(changeset)}")
              {:error, Gap.traverse_changeset_errors(changeset)}
          end

        {:error, reason} ->
          Logger.error("Failed to read HTML file #{product_data.html_file_path}: #{inspect(reason)}")
          {:error, {:file_read_error, reason}}
      end
    end
  end
end
