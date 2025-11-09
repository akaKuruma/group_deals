defmodule GroupDeals.Gap do
  @moduledoc """
  The Gap context.
  """

  import Ecto.Query, warn: false
  alias GroupDeals.Repo

  alias GroupDeals.Gap.PagesGroup

  @doc """
  Returns the list of pages_groups.

  ## Examples

      iex> list_pages_groups()
      [%PagesGroup{}, ...]

  """
  def list_pages_groups do
    Repo.all(PagesGroup)
  end

  @doc """
  Gets a single pages_group.

  Raises `Ecto.NoResultsError` if the Pages group does not exist.

  ## Examples

      iex> get_pages_group!(123)
      %PagesGroup{}

      iex> get_pages_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pages_group!(id), do: Repo.get!(PagesGroup, id)

  @doc """
  Creates a pages_group.

  ## Examples

      iex> create_pages_group(%{field: value})
      {:ok, %PagesGroup{}}

      iex> create_pages_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pages_group(attrs) do
    %PagesGroup{}
    |> PagesGroup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a pages_group.

  ## Examples

      iex> update_pages_group(pages_group, %{field: new_value})
      {:ok, %PagesGroup{}}

      iex> update_pages_group(pages_group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pages_group(%PagesGroup{} = pages_group, attrs) do
    pages_group
    |> PagesGroup.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a pages_group.

  ## Examples

      iex> delete_pages_group(pages_group)
      {:ok, %PagesGroup{}}

      iex> delete_pages_group(pages_group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pages_group(%PagesGroup{} = pages_group) do
    Repo.delete(pages_group)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pages_group changes.

  ## Examples

      iex> change_pages_group(pages_group)
      %Ecto.Changeset{data: %PagesGroup{}}

  """
  def change_pages_group(%PagesGroup{} = pages_group, attrs \\ %{}) do
    PagesGroup.changeset(pages_group, attrs)
  end
end
