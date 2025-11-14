defmodule GroupDeals.Gap.GapApiProductsJsonProcessor do
  @moduledoc """
  Processes Gap API JSON responses to extract and store products.
  """

  alias GroupDeals.Gap
  alias GroupDeals.Gap.HttpClient
  require Logger

  @doc """
  Processes all GapPages sequentially, extracting products from JSON responses.
  Returns {:ok, total_product_count} on success or :error on failure.
  """
  def process_pages(gap_data_fetch, gap_pages, _folder_path) do
    total_products =
      Enum.reduce_while(gap_pages, {gap_data_fetch, 0}, fn gap_page, {current_fetch, acc} ->
        case process_page(current_fetch, gap_page) do
          {:ok, product_count} ->
            # Update processed_pages
            new_total_products = acc + product_count

            case Gap.update_gap_data_fetch(current_fetch, %{
                   processed_pages: current_fetch.processed_pages + 1,
                   total_products: new_total_products
                 }) do
              {:ok, updated_fetch} ->
                {:cont, {updated_fetch, acc + product_count}}

              {:error, changeset} ->
                Logger.error("Failed to update GapDataFetch: #{inspect(changeset)}")
                mark_as_failed(current_fetch, "Failed to update progress")
                {:halt, {:error, :update_failed}}
            end

          {:error, reason} ->
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

  defp process_page(gap_data_fetch, gap_page) do
    Logger.info("Processing GapPage: #{gap_page.title} (#{gap_page.api_url})")

    case HttpClient.fetch_json_api(gap_page.api_url) do
      {:ok, json_body} ->
        extract_and_store_products(gap_data_fetch, json_body)

      {:error, reason} ->
        if Mix.env() != :test,
          do: Logger.error("Failed to fetch API for page #{gap_page.id}: #{inspect(reason)}")

        {:error, reason}
    end
  end

  defp extract_and_store_products(gap_data_fetch, json_body) do
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

          # Extract image paths
          image_paths = Enum.map(images, fn img -> Map.get(img, "path") end)

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
                     gap_data_fetch_id: gap_data_fetch.id,
                     folder_timestamp: gap_data_fetch.folder_timestamp,
                     api_image_paths: image_paths,
                     marketing_flag: marketing_flag
                   }) do
                {:ok, _gap_product_data} ->
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

  defp mark_as_failed(gap_data_fetch, error_message) do
    Gap.update_gap_data_fetch(gap_data_fetch, %{
      status: :failed,
      error_message: error_message
    })
  end
end
