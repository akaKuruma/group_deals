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

  alias GroupDeals.Gap.GapPage

  @spec list_group_pages(group_id :: binary) :: [GapPage.t()]
  def list_group_pages(group_id) do
    Repo.all(from p in GapPage, where: p.pages_group_id == ^group_id, preload: :pages_group)
  end

  @doc """
  Returns the list of gap_pages.

  ## Examples

      iex> list_gap_pages()
      [%GapPage{}, ...]

  """
  def list_gap_pages do
    Repo.all(GapPage)
  end

  @spec get_group_page!(group_id :: binary, page_id :: binary) :: GapPage.t()
  def get_group_page!(group_id, page_id) do
    GapPage
    |> where([p], p.pages_group_id == ^group_id and p.id == ^page_id)
    |> preload(:pages_group)
    |> Repo.one!()
  end

  @doc """
  Gets a single gap_page.

  Raises `Ecto.NoResultsError` if the Gap page does not exist.

  ## Examples

      iex> get_gap_page!(123)
      %GapPage{}

      iex> get_gap_page!(456)
      ** (Ecto.NoResultsError)

  """
  def get_gap_page!(id), do: Repo.get!(GapPage, id)

  @doc """
  Creates a gap_page.

  ## Examples

      iex> create_gap_page(%PagesGroup{}, %{field: value})
      {:ok, %GapPage{}}

      iex> create_gap_page(%PagesGroup{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_gap_page(%PagesGroup{} = pages_group, attrs) do
    %GapPage{}
    |> Map.put(:pages_group_id, pages_group.id)
    |> GapPage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a gap_page.

  ## Examples

      iex> update_gap_page(gap_page, %{field: new_value})
      {:ok, %GapPage{}}

      iex> update_gap_page(gap_page, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_gap_page(%GapPage{} = gap_page, attrs) do
    gap_page
    |> GapPage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a gap_page.

  ## Examples

      iex> delete_gap_page(gap_page)
      {:ok, %GapPage{}}

      iex> delete_gap_page(gap_page)
      {:error, %Ecto.Changeset{}}

  """
  def delete_gap_page(%GapPage{} = gap_page) do
    Repo.delete(gap_page)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking gap_page changes.

  ## Examples

      iex> change_gap_page(gap_page)
      %Ecto.Changeset{data: %GapPage{}}

  """
  def change_gap_page(%GapPage{} = gap_page, attrs \\ %{}) do
    GapPage.changeset(gap_page, attrs)
  end
end
