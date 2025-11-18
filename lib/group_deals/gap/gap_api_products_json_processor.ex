defmodule GroupDeals.Gap.GapApiProductsJsonProcessor do
  @moduledoc """
  Processes Gap API JSON responses to extract and store products.
  """

  alias GroupDeals.Gap
  alias GroupDeals.Gap.HttpClient
  alias GroupDeals.Workers.DownloadProductImageWorker
  alias Oban
  require Logger

  @doc """
  Processes all GapPages sequentially, extracting products from JSON responses.
  Returns {:ok, total_product_count} on success or :error on failure.
  """
  def process_pages(gap_group_products_fetch_status, gap_pages, _folder_path) do
    total_products =
      Enum.reduce_while(gap_pages, {gap_group_products_fetch_status, 0}, fn gap_page, {current_fetch, acc} ->
        case process_page(current_fetch, gap_page) do
          {:ok, product_count} ->
            # Atomically increment product_list_page_succeeded_count
            Gap.increment_gap_group_products_fetch_status_counter(
              current_fetch.id,
              :product_list_page_succeeded_count,
              1
            )

            # Update products_total (calculated from accumulator)
            new_total_products = acc + product_count
            case Gap.update_gap_group_products_fetch_status(current_fetch, %{
                   products_total: new_total_products
                 }) do
              {:ok, updated_fetch} ->
                {:cont, {updated_fetch, acc + product_count}}

              {:error, changeset} ->
                Logger.error("Failed to update GapGroupProductsFetchStatus: #{inspect(changeset)}")
                mark_as_failed(current_fetch, "Failed to update progress")
                {:halt, {:error, :update_failed}}
            end

          {:error, reason} ->
            # Increment failed count
            increment_failed_count(current_fetch)
            mark_as_failed(current_fetch, "Failed to process page: #{inspect(reason)}")
            {:halt, {:error, reason}}
        end
      end)

    case total_products do
      {:error, _reason} ->
        :error

      {_updated_fetch, count} ->
        {:ok, count}
    end
  end

  defp process_page(gap_group_products_fetch_status, gap_page) do
    Logger.info("Processing GapPage: #{gap_page.title} (#{gap_page.api_url})")

    case HttpClient.fetch_json_api(gap_page.api_url) do
      {:ok, json_body} ->
        extract_and_store_products(gap_group_products_fetch_status, json_body)

      {:error, reason} ->
        if Mix.env() != :test,
          do: Logger.error("Failed to fetch API for page #{gap_page.id}: #{inspect(reason)}")

        {:error, reason}
    end
  end

  defp extract_and_store_products(gap_group_products_fetch_status, json_body) do
    products =
      case Map.get(json_body, "products") do
        list when is_list(list) -> list
        _ -> []
      end

    product_count =
      Enum.reduce(products, 0, fn product, acc ->
        style_id = Map.get(product, "styleId")
        style_name = Map.get(product, "styleName")

        style_colors =
          case Map.get(product, "styleColors") do
            list when is_list(list) -> list
            _ -> []
          end

        Enum.reduce(style_colors, acc, fn style_color, color_acc ->
          cc_id = Map.get(style_color, "ccId")
          cc_name = Map.get(style_color, "ccName")

          images =
            case Map.get(style_color, "images") do
              list when is_list(list) -> list
              _ -> []
            end

          # Extract primary image path (P01 type) to match Python scraper behavior
          primary_image_path = extract_primary_image_path(images)

          # Extract marketing flag from ccLevelMarketingFlags
          marketing_flag = extract_marketing_flag(style_color)

          # Get or create GapProduct
          case Gap.get_or_create_gap_product(%{
                 cc_id: to_string(cc_id),
                 style_id: to_string(style_id),
                 style_name: style_name,
                 cc_name: cc_name
               }) do
            {:ok, gap_product} ->
              # Create GapProductData with marketing_flag
              case Gap.create_gap_product_data(%{
                     product_id: gap_product.id,
                     gap_group_products_fetch_status_id: gap_group_products_fetch_status.id,
                     folder_timestamp: gap_group_products_fetch_status.folder_timestamp,
                     api_image_paths: [primary_image_path],
                     marketing_flag: marketing_flag
                   }) do
                {:ok, gap_product_data} ->
                  # Schedule image download job immediately
                  schedule_image_download(gap_product_data.id, gap_group_products_fetch_status.id)

                  color_acc + 1

                {:error, changeset} ->
                  Logger.error("Failed to create GapProductData: #{inspect(changeset)}")
                  color_acc
              end

            {:error, changeset} ->
              Logger.error("Failed to get/create GapProduct: #{inspect(changeset)}")
              color_acc
          end
        end)
      end)

    {:ok, product_count}
  end

  # Extracts marketing flag from ccLevelMarketingFlags array
  # Returns the first flag's content, or empty string if none found
  defp extract_marketing_flag(style_color) do
    case Map.get(style_color, "ccLevelMarketingFlags") do
      flags when is_list(flags) and length(flags) > 0 ->
        # Get the first flag's content
        first_flag = List.first(flags)
        Map.get(first_flag, "content", "")

      _ ->
        ""
    end
  end

  # Extracts the primary image path (P01 type) to match Python scraper behavior
  # Falls back to first image with position 1 if P01 not found
  # Returns empty string if no images found
  defp extract_primary_image_path(images) when is_list(images) do
    # First, try to find P01 (Primary) image
    p01_image = Enum.find(images, fn img -> Map.get(img, "type") == "P01" end)

    case p01_image do
      nil ->
        # Fallback: find first image with position 1
        position_1_image = Enum.find(images, fn img -> Map.get(img, "position") == 1 end)

        case position_1_image do
          nil -> ""
          img -> Map.get(img, "path", "")
        end

      img ->
        Map.get(img, "path", "")
    end
  end

  defp extract_primary_image_path(_), do: ""

  # Schedules the DownloadProductImageWorker job
  defp schedule_image_download(product_data_id, gap_data_fetch_id) do
    %{
      "product_data_id" => product_data_id,
      "gap_data_fetch_id" => gap_data_fetch_id
    }
    |> DownloadProductImageWorker.new()
    |> Oban.insert()
  end

  defp increment_failed_count(gap_group_products_fetch_status) do
    # Use atomic increment to prevent race conditions
    Gap.increment_gap_group_products_fetch_status_counter(
      gap_group_products_fetch_status.id,
      :product_list_page_failed_count,
      1
    )
  end

  defp mark_as_failed(gap_group_products_fetch_status, error_message) do
    Gap.update_gap_group_products_fetch_status(gap_group_products_fetch_status, %{
      status: :failed,
      error_message: error_message
    })
  end
end
