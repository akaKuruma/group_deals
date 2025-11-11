defmodule GroupDeals.GapFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GroupDeals.Gap` context.
  """
  alias GroupDeals.Gap

  @doc """
  Generate a pages_group.
  """
  def pages_group_fixture(attrs \\ %{}) do
    {:ok, pages_group} =
      attrs
      |> Enum.into(%{
        title: "some title"
      })
      |> Gap.create_pages_group()

    pages_group
  end

  @doc """
  Generate a gap_page.
  """
  def gap_page_fixture(attrs \\ %{}) do
    {:ok, gap_page} =
      Gap.create_gap_page(handle_pages_group_field(attrs), handle_page_attrs(attrs))

    gap_page
  end

  defp handle_pages_group_field(attrs) do
    case attrs do
      %{"pages_group_id" => pages_group_id} -> Gap.get_pages_group!(pages_group_id)
      _ -> pages_group_fixture()
    end
  end

  defp handle_page_attrs(attrs) do
    attrs
    |> Enum.into(%{
      title: "Women - logo",
      web_page_url: "https://www.gap.com/women/logo",
      api_url: "https://www.gap.com/api/v1/products/women/logo",
      web_page_parameters: %{}
    })
  end

  @doc """
  Generate a gap_data_fetch.
  """
  def gap_data_fetch_fixture(attrs \\ %{}) do
    pages_group =
      case attrs do
        %{pages_group_id: pages_group_id} -> Gap.get_pages_group!(pages_group_id)
        %{"pages_group_id" => pages_group_id} -> Gap.get_pages_group!(pages_group_id)
        _ -> pages_group_fixture()
      end

    {:ok, gap_data_fetch} =
      attrs
      |> Enum.into(%{
        pages_group_id: pages_group.id,
        status: :pending,
        folder_timestamp: "20241111000000"
      })
      |> Gap.create_gap_data_fetch()

    gap_data_fetch
  end
end
