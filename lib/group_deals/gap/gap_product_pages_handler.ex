defmodule GroupDeals.Gap.GapProductPagesHandler do
  @moduledoc """
  Handles processing of product pages: fetching HTML and saving to disk.
  """

  alias GroupDeals.Gap
  alias GroupDeals.Gap.HttpClient
  alias GroupDeals.Gap.ProductUrlBuilder
  alias GroupDeals.Workers.ParseProductPagesWorker
  alias Oban
  require Logger

  @doc """
  Processes all ProductData records sequentially, fetching HTML and saving to disk.

  Returns `{:ok, count}` on success or `{:error, reason}` on failure.
  """
  def process_products(
        gap_group_products_fetch_status,
        product_data_list,
        gap_page,
        pages_group_id,
        id_store_category
      ) do
    folder_path =
      Path.join(["/tmp/gap_site", pages_group_id, gap_group_products_fetch_status.folder_timestamp])

    # Ensure folder exists
    File.mkdir_p!(folder_path)

    Enum.reduce_while(product_data_list, {gap_group_products_fetch_status, 0}, fn product_data,
                                                                 {current_fetch, processed} ->
      case process_product(
             product_data,
             gap_page,
             folder_path,
             gap_group_products_fetch_status.id,
             id_store_category
           ) do
        {:ok, _updated_product_data} ->
          # Update product_page_fetched_count counter atomically
          Gap.increment_gap_group_products_fetch_status_counter(
            current_fetch.id,
            :product_page_fetched_count,
            1
          )

          # Reload fetch status for next iteration (to get updated counter)
          updated_fetch = Gap.get_active_gap_group_products_fetch_status!(current_fetch.id)
          {:cont, {updated_fetch, processed + 1}}

        {:error, reason} ->
          Logger.error("Failed to process product #{product_data.id}: #{inspect(reason)}")
          # Note: Failed product page fetches are tracked via page_fetch_status in GapProductData
          mark_as_failed(current_fetch, "Failed to fetch product page: #{inspect(reason)}")
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:error, reason} -> {:error, reason}
      {_updated_fetch, count} -> {:ok, count}
    end
  end

  defp process_product(product_data, gap_page, folder_path, gap_data_fetch_id, id_store_category) do
    product = product_data.product

    if is_nil(product) or is_nil(product.cc_id) do
      {:error, :missing_cc_id}
    else
      # Build product URL
      product_url = ProductUrlBuilder.build_product_url(product.cc_id, gap_page || %{})

      # Fetch HTML and save to file using the shared session
      fetch_and_save_html(
        product_data,
        product_url,
        product.cc_id,
        folder_path,
        gap_data_fetch_id,
        id_store_category
      )
    end
  end

  defp fetch_and_save_html(
         product_data,
         product_url,
         cc_id,
         folder_path,
         gap_data_fetch_id,
         id_store_category
       ) do
    case HttpClient.fetch_product_html_page(product_url) do
      {:ok, html} ->
        # Save HTML to file
        file_path = Path.join(folder_path, "#{cc_id}.html")
        File.write!(file_path, html)

        # Update ProductData with file path
        case Gap.update_gap_product_data(product_data, %{html_file_path: file_path}) do
          {:ok, updated} ->
            # Schedule parsing job for this product
            schedule_parsing_job(updated.id, gap_data_fetch_id, id_store_category)
            {:ok, updated}

          {:error, changeset} ->
            {:error, {:update_failed, changeset}}
        end

      {:error, reason} ->
        {:error, {:fetch_failed, reason}}
    end
  end

  defp schedule_parsing_job(product_data_id, gap_data_fetch_id, id_store_category) do
    %{
      gap_data_fetch_id: gap_data_fetch_id,
      product_data_id: product_data_id,
      id_store_category: id_store_category
    }
    |> ParseProductPagesWorker.new()
    |> Oban.insert()
  end

  defp mark_as_failed(gap_group_products_fetch_status, error_message) do
    Gap.update_gap_group_products_fetch_status(gap_group_products_fetch_status, %{
      status: :failed,
      error_message: error_message
    })
  end
end
