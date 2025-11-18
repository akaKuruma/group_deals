defmodule GroupDeals.Gap.FetchCoordinator do
  @moduledoc """
  Coordinates the start of a Gap data fetch process.
  """

  alias GroupDeals.Gap
  alias GroupDeals.Gap.GapGroupProductsFetchStatus
  alias GroupDeals.Workers.FetchGapPageJsonWorker

  @doc """
  Starts a new fetch process for a PagesGroup.

  Validates that no active fetch exists, creates the GapGroupProductsFetchStatus record,
  generates a timestamp, and schedules the first Oban job.

  Returns {:ok, gap_group_products_fetch_status} or {:error, reason}
  """
  def start_fetch(%Gap.PagesGroup{} = pages_group) do
    # Check for active fetch
    case Gap.get_active_fetch_status_for_pages_group(pages_group.id) do
      nil ->
        do_start_fetch(pages_group)

      _active_fetch ->
        {:error, :active_fetch_exists}
    end
  end

  def finish_fetch(%GapGroupProductsFetchStatus{} = gap_group_products_fetch_status, attrs) do
    attrs = Map.merge(attrs, %{completed_at: DateTime.utc_now()})

    gap_group_products_fetch_status
    |> Gap.update_gap_group_products_fetch_status(attrs)
  end

  defp do_start_fetch(pages_group) do
    timestamp = generate_timestamp()

    attrs = %{
      pages_group_id: pages_group.id,
      status: :pending,
      folder_timestamp: timestamp
    }

    case Gap.create_gap_group_products_fetch_status(attrs) do
      {:ok, gap_group_products_fetch_status} ->
        schedule_first_job(gap_group_products_fetch_status)
        {:ok, gap_group_products_fetch_status}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp schedule_first_job(%GapGroupProductsFetchStatus{id: gap_group_products_fetch_status_id}) do
    %{gap_data_fetch_id: gap_group_products_fetch_status_id}
    |> FetchGapPageJsonWorker.new()
    |> Oban.insert()
  end

  defp generate_timestamp do
    DateTime.utc_now()
    |> Calendar.strftime("%Y%m%d%H%M%S")
  end
end
