defmodule GroupDeals.Workers.DownloadProductImageWorker do
  @moduledoc """
  Oban worker that downloads the primary product image.

  This worker:
  1. Loads GapProductData with preloaded product (to get cc_id)
  2. Extracts primary image path from api_image_paths
  3. Checks if image already exists at target path
  4. Downloads image if it doesn't exist
  5. Updates ProductData and GapGroupProductsFetchStatus progress
  """

  alias GroupDeals.Gap
  alias Oban
  require Logger

  use Oban.Worker, queue: :download_product_image

  @base_url "https://www.gapfactory.com"
  @base_path "/tmp/gap_site/products"

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "product_data_id" => product_data_id,
          "gap_data_fetch_id" => gap_data_fetch_id
        }
      }) do
    # Verify the fetch is still active
    try do
      gap_group_products_fetch_status = Gap.get_active_gap_group_products_fetch_status!(gap_data_fetch_id)
      product_data = Gap.get_gap_product_data!(product_data_id)

      if product_data.gap_group_products_fetch_status_id != gap_data_fetch_id do
        Logger.error(
          "ProductData #{product_data_id} does not belong to GapGroupProductsFetchStatus #{gap_data_fetch_id}"
        )

        {:error, :mismatched_fetch}
      else
        download_product_image(product_data, gap_group_products_fetch_status)
      end
    rescue
      Ecto.NoResultsError ->
        Logger.error("GapGroupProductsFetchStatus or ProductData not found: #{gap_data_fetch_id}/#{product_data_id}")
        {:error, :not_found}
    end
  end

  defp download_product_image(product_data, gap_group_products_fetch_status) do
    # Extract primary image path from api_image_paths (first element)
    image_path = List.first(product_data.api_image_paths || [])

    if image_path == nil or image_path == "" do
      # No image to download, but still increment product_image_downloaded_count
      increment_product_image_downloaded_count(gap_group_products_fetch_status)
      :ok
    else
      # Get cc_id from preloaded product
      cc_id = if product_data.product, do: product_data.product.cc_id, else: nil

      if cc_id == nil do
        Logger.error("ProductData #{product_data.id} has no associated product with cc_id")
        {:error, :missing_cc_id}
      else
        # Build target path: /tmp/gap_site/products/{cc_id}/images/{filename}
        filename = extract_filename(image_path)
        target_path = Path.join([@base_path, cc_id, "images", filename])

        # Check if file already exists
        if File.exists?(target_path) do
          # File exists, update ProductData if needed and increment counter
          update_product_data_if_needed(product_data, target_path)
          increment_product_image_downloaded_count(gap_group_products_fetch_status)
          :ok
        else
          # File doesn't exist, download it
          download_and_save_image(image_path, target_path, product_data, gap_group_products_fetch_status)
        end
      end
    end
  end

  defp download_and_save_image(image_path, target_path, product_data, gap_group_products_fetch_status) do
    # Build full image URL
    full_url = build_image_url(image_path)

    # Create directory structure
    target_dir = Path.dirname(target_path)
    File.mkdir_p!(target_dir)

    # Download image using Req
    case download_image(full_url) do
      {:ok, image_data} ->
        # Save to target path
        case File.write(target_path, image_data) do
          :ok ->
            # Update ProductData with image path
            case Gap.update_gap_product_data(product_data, %{
                   image_paths: [target_path]
                 }) do
              {:ok, _} ->
                increment_product_image_downloaded_count(gap_group_products_fetch_status)
                :ok

              {:error, changeset} ->
                Logger.error("Failed to update ProductData: #{inspect(changeset)}")
                {:error, Gap.traverse_changeset_errors(changeset)}
            end

          {:error, reason} ->
            Logger.error("Failed to write image file #{target_path}: #{inspect(reason)}")
            {:error, {:file_write_error, reason}}
        end

      {:error, reason} ->
        Logger.error("Failed to download image from #{full_url}: #{inspect(reason)}")
        {:error, {:download_error, reason}}
    end
  end

  defp download_image(url) do
    try do
      case Req.get(url, receive_timeout: 30_000, retry: false) do
        {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
          {:ok, body}

        {:ok, %Req.Response{status: status}} ->
          {:error, {:http_error, status}}

        {:error, reason} ->
          {:error, {:request_error, reason}}
      end
    rescue
      e -> {:error, {:exception, Exception.message(e)}}
    catch
      :exit, reason -> {:error, {:exit, reason}}
    end
  end

  defp build_image_url(path) when is_binary(path) do
    if String.starts_with?(path, "/") do
      @base_url <> path
    else
      @base_url <> "/" <> path
    end
  end

  defp extract_filename(path) when is_binary(path) do
    path
    |> String.split("/")
    |> List.last()
  end

  defp extract_filename(_), do: "image.jpg"

  defp update_product_data_if_needed(product_data, target_path) do
    # Only update if image_paths is nil or empty
    if is_nil(product_data.image_paths) or product_data.image_paths == [] do
      case Gap.update_gap_product_data(product_data, %{image_paths: [target_path]}) do
        {:ok, _} -> :ok
        {:error, changeset} -> Logger.warning("Failed to update ProductData: #{inspect(changeset)}")
      end
    else
      :ok
    end
  end

  defp increment_product_image_downloaded_count(gap_group_products_fetch_status) do
    # Use atomic increment to prevent race conditions with concurrent workers
    Gap.increment_gap_group_products_fetch_status_counter(
      gap_group_products_fetch_status.id,
      :product_image_downloaded_count,
      1
    )
  end
end
