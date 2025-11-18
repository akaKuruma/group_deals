defmodule GroupDeals.Workers.FetchProductPagesWorker do
  @moduledoc """
  Oban worker that initiates Puppeteer script to fetch HTML product pages.

  This is the second job in the workflow. It:
  1. Updates status to :fetching_product_page
  2. Sets product_page_url and page_fetch_status for each ProductData
  3. Starts Puppeteer script asynchronously to fetch pages
  4. Schedules CheckPuppeteerCompletionWorker to monitor completion
  5. When complete, parsing jobs are scheduled by CheckPuppeteerCompletionWorker
  """

  alias GroupDeals.Gap
  alias GroupDeals.Gap.ProductUrlBuilder
  alias GroupDeals.Workers.CheckPuppeteerCompletionWorker
  alias Oban
  require Logger

  use Oban.Worker, queue: :fetch_product_html_page

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"gap_data_fetch_id" => gap_data_fetch_id}}) do
    gap_group_products_fetch_status = Gap.get_active_gap_group_products_fetch_status!(gap_data_fetch_id)
    pages_group = gap_group_products_fetch_status.pages_group

    # Get first GapPage for URL parameters (all products share same category context)
    gap_page = get_first_gap_page(pages_group.gap_pages)

    # 1. Update status to :processing
    case Gap.update_gap_group_products_fetch_status(gap_group_products_fetch_status, %{
           status: :processing
         }) do
      {:ok, updated_fetch} ->
        # 2. Process all products - set URLs and start Puppeteer script
        case process_all_products(updated_fetch, gap_data_fetch_id, gap_page, pages_group.id) do
          {:ok, _count} ->
            # Script started, completion check will be scheduled by process_all_products
            :ok

          {:error, reason} ->
            if Mix.env() != :test,
              do: Logger.error("Failed to process products: #{inspect(reason)}")

            mark_as_failed(gap_group_products_fetch_status, "Failed to process products: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, changeset} ->
        if Mix.env() != :test,
          do: Logger.error("Failed to update GapGroupProductsFetchStatus status: #{inspect(changeset)}")

        mark_as_failed(gap_group_products_fetch_status, "Failed to update status")
        {:error, Gap.traverse_changeset_errors(changeset)}
    end
  end

  defp get_first_gap_page([]), do: nil
  defp get_first_gap_page([gap_page | _]), do: gap_page

  defp process_all_products(gap_group_products_fetch_status, gap_data_fetch_id, gap_page, pages_group_id) do
    # Get all ProductData records for this fetch
    product_data_list = Gap.list_gap_product_data_for_fetch(gap_data_fetch_id)

    # Set products_total if not already set
    updated_fetch =
      if gap_group_products_fetch_status.products_total == 0 do
        case Gap.update_gap_group_products_fetch_status(gap_group_products_fetch_status, %{
               products_total: length(product_data_list)
             }) do
          {:ok, fetch} -> fetch
          {:error, _} -> gap_group_products_fetch_status
        end
      else
        gap_group_products_fetch_status
      end

    # Determine id_store_category from gap_page nav parameter
    id_store_category = determine_id_store_category(gap_page)

    # Build folder path
    folder_path =
      Path.join(["/tmp/gap_site", pages_group_id, updated_fetch.folder_timestamp])

    # Ensure folder exists
    File.mkdir_p!(folder_path)

    # Update each ProductData with product_page_url and set status to pending
    update_result =
      Enum.reduce_while(product_data_list, :ok, fn product_data, acc ->
        if product_data.product && product_data.product.cc_id do
          product_url =
            ProductUrlBuilder.build_product_url(product_data.product.cc_id, gap_page || %{})

          case Gap.update_gap_product_data(product_data, %{
                 product_page_url: product_url,
                 page_fetch_status: :pending
               }) do
            {:ok, _} ->
              {:cont, acc}

            {:error, changeset} ->
              Logger.error(
                "Failed to update ProductData #{product_data.id}: #{inspect(changeset)}"
              )

              {:halt, {:error, :update_failed}}
          end
        else
          {:cont, acc}
        end
      end)

    case update_result do
      {:error, reason} ->
        {:error, reason}

      _ ->
        # Start Puppeteer script asynchronously
        # In production (release), script is at /app/scripts/fetch_pages.js
        # In development, script is at project root scripts/fetch_pages.js
        script_path =
          if Code.ensure_loaded?(Mix) do
            # Development mode
            Path.expand("scripts/fetch_pages.js", File.cwd!())
          else
            # Production mode (release)
            "/app/scripts/fetch_pages.js"
          end

        # Get database URL from Repo configuration
        database_url = get_database_url()

        # Start script in background (don't wait for completion)
        Task.start(fn ->
          System.cmd("node", [script_path, gap_data_fetch_id],
            stderr_to_stdout: true,
            env: [{"DATABASE_URL", database_url}]
          )
        end)

        Logger.info("Started Puppeteer script for fetch #{gap_data_fetch_id}")

        # Schedule first completion check
        schedule_completion_check(gap_data_fetch_id, id_store_category)

        {:ok, length(product_data_list)}
    end
  end

  defp schedule_completion_check(gap_data_fetch_id, id_store_category) do
    %{"gap_data_fetch_id" => gap_data_fetch_id, "id_store_category" => id_store_category}
    |> CheckPuppeteerCompletionWorker.new(schedule_in: 30)
    |> Oban.insert()
  end

  # Determines id_store_category from gap_page nav parameter
  # Maps nav categories to store category IDs based on Python script
  # Default to women's
  defp determine_id_store_category(nil), do: 5

  defp determine_id_store_category(%{web_page_parameters: nil}), do: 5

  defp determine_id_store_category(%{web_page_parameters: params}) do
    nav = Map.get(params, "nav") || Map.get(params, :nav) || ""

    cond do
      String.contains?(nav, "Women") -> 5
      String.contains?(nav, "Men") -> 4
      String.contains?(nav, "Girls") -> 253
      String.contains?(nav, "Boys") -> 67
      String.contains?(nav, "Baby Girl") -> 255
      String.contains?(nav, "Baby Boy") -> 10
      String.contains?(nav, "Toddler Girls") -> 254
      String.contains?(nav, "Toddler Boys") -> 68
      # Default to women's
      true -> 5
    end
  end

  defp determine_id_store_category(_), do: 5

  defp mark_as_failed(gap_group_products_fetch_status, error_message) do
    Gap.update_gap_group_products_fetch_status(gap_group_products_fetch_status, %{
      status: :failed,
      error_message: error_message
    })
  end

  # Gets database URL from Repo configuration
  # Handles both :url format and individual component format
  defp get_database_url do
    repo_config = Application.get_env(:group_deals, GroupDeals.Repo, [])

    case Keyword.get(repo_config, :url) do
      nil ->
        # Build URL from individual components (dev/test)
        username = Keyword.get(repo_config, :username, "postgres")
        password = Keyword.get(repo_config, :password, "postgres")
        hostname = Keyword.get(repo_config, :hostname, "localhost")
        database = Keyword.get(repo_config, :database, "group_deals_dev")
        port = Keyword.get(repo_config, :port, 5432)

        # Build postgres:// URL (script will convert ecto:// if needed)
        "postgres://#{username}:#{password}@#{hostname}:#{port}/#{database}"

      url when is_binary(url) ->
        # URL already configured (prod or if explicitly set)
        url
    end
  end
end
