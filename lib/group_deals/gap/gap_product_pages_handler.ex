defmodule GroupDeals.Gap.GapProductPagesHandler do
  @moduledoc """
  Handles processing of product pages: fetching HTML and saving to disk.
  """

  alias GroupDeals.Gap
  alias GroupDeals.Gap.ApiClient
  alias GroupDeals.Gap.ProductUrlBuilder
  require Logger

  @doc """
  Processes all ProductData records sequentially, fetching HTML and saving to disk.

  Returns `{:ok, count}` on success or `{:error, reason}` on failure.
  """
  def process_products(gap_data_fetch, product_data_list, gap_page, pages_group_id) do
    folder_path =
      Path.join(["tmp", "gap_site", pages_group_id, gap_data_fetch.folder_timestamp])

    # Ensure folder exists
    File.mkdir_p!(folder_path)

    # Establish session once for all product requests
    case ApiClient.create_session() do
      {:ok, session} ->
        Enum.reduce_while(product_data_list, {gap_data_fetch, 0, session}, fn product_data,
                                                                              {current_fetch, processed, current_session} ->
          case process_product(product_data, gap_page, folder_path, current_session) do
            {:ok, _updated_product_data, updated_session} ->
              # Update processed_products counter
              case Gap.update_gap_data_fetch(current_fetch, %{
                     processed_products: current_fetch.processed_products + 1
                   }) do
                {:ok, updated_fetch} ->
                  {:cont, {updated_fetch, processed + 1, updated_session}}

                {:error, changeset} ->
                  Logger.error("Failed to update GapDataFetch progress: #{inspect(changeset)}")
                  mark_as_failed(current_fetch, "Failed to update progress")
                  {:halt, {:error, :update_failed}}
              end

            {:error, reason} ->
              Logger.error("Failed to process product #{product_data.id}: #{inspect(reason)}")
              mark_as_failed(current_fetch, "Failed to fetch product page: #{inspect(reason)}")
              {:halt, {:error, reason}}
          end
        end)
        |> case do
          {:error, reason} -> {:error, reason}
          {_updated_fetch, count, _session} -> {:ok, count}
        end

      {:error, reason} ->
        Logger.error("Failed to create session: #{inspect(reason)}")
        mark_as_failed(gap_data_fetch, "Failed to create session: #{inspect(reason)}")
        {:error, {:session_failed, reason}}
    end
  end

  defp process_product(product_data, gap_page, folder_path, session) do
    product = product_data.product

    if is_nil(product) or is_nil(product.cc_id) do
      {:error, :missing_cc_id}
    else
      # Build product URL
      product_url = ProductUrlBuilder.build_product_url(product.cc_id, gap_page || %{})

      # Fetch HTML and save to file using the shared session
      fetch_and_save_html(product_data, product_url, product.cc_id, folder_path, session)
    end
  end

  defp fetch_and_save_html(product_data, product_url, cc_id, folder_path, session) do
    case ApiClient.fetch_product_html(product_url, session) do
      {:ok, html, updated_session} ->
        # Save HTML to file
        file_path = Path.join(folder_path, "#{cc_id}.html")
        File.write!(file_path, html)

        # Update ProductData with file path
        case Gap.update_gap_product_data(product_data, %{html_file_path: file_path}) do
          {:ok, updated} -> {:ok, updated, updated_session}
          {:error, changeset} -> {:error, {:update_failed, changeset}}
        end

      {:error, reason} ->
        {:error, {:fetch_failed, reason}}
    end
  end

  defp mark_as_failed(gap_data_fetch, error_message) do
    Gap.update_gap_data_fetch(gap_data_fetch, %{
      status: :failed,
      error_message: error_message
    })
  end
end
