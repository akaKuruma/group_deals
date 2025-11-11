defmodule GroupDeals.Gap.FetchCoordinator do
  @moduledoc """
  Coordinates the start of a Gap data fetch process.
  """

  alias GroupDeals.Gap
  alias GroupDeals.Gap.GapDataFetch
  alias GroupDeals.Workers.FetchGapPageJsonWorker

  @doc """
  Starts a new fetch process for a PagesGroup.

  Validates that no active fetch exists, creates the GapDataFetch record,
  generates a timestamp, and schedules the first Oban job.

  Returns {:ok, gap_data_fetch} or {:error, reason}
  """
  def start_fetch(%Gap.PagesGroup{} = pages_group) do
    # Check for active fetch
    case Gap.get_active_fetch_for_pages_group(pages_group.id) do
      nil ->
        do_start_fetch(pages_group)

      _active_fetch ->
        {:error, :active_fetch_exists}
    end
  end

  def finish_fetch(%GapDataFetch{} = gap_data_fetch, attrs) do
    attrs = Map.merge(attrs, %{completed_at: DateTime.utc_now()})

    gap_data_fetch
    |> Gap.update_gap_data_fetch(attrs)
  end

  defp do_start_fetch(pages_group) do
    timestamp = generate_timestamp()

    attrs = %{
      pages_group_id: pages_group.id,
      status: :pending,
      folder_timestamp: timestamp
    }

    case Gap.create_gap_data_fetch(attrs) do
      {:ok, gap_data_fetch} ->
        schedule_first_job(gap_data_fetch)
        {:ok, gap_data_fetch}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp schedule_first_job(%GapDataFetch{id: gap_data_fetch_id}) do
    %{gap_data_fetch_id: gap_data_fetch_id}
    |> FetchGapPageJsonWorker.new()
    |> Oban.insert()
  end

  defp generate_timestamp do
    DateTime.utc_now()
    |> Calendar.strftime("%Y%m%d%H%M%S")
  end
end
