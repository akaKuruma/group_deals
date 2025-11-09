defmodule GroupDeals.GapFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GroupDeals.Gap` context.
  """

  @doc """
  Generate a pages_group.
  """
  def pages_group_fixture(attrs \\ %{}) do
    {:ok, pages_group} =
      attrs
      |> Enum.into(%{
        title: "some title"
      })
      |> GroupDeals.Gap.create_pages_group()

    pages_group
  end
end
