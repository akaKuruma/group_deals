defmodule GroupDeals.Gap.GapPage do
  use Ecto.Schema
  import Ecto.Changeset
  alias GroupDeals.Gap.ApiUrlBuilder
  alias GroupDeals.Gap.PagesGroup
  alias Ecto.Changeset

  @type t :: %__MODULE__{
    id: binary,
    title: String.t(),
    web_page_url: String.t(),
    api_url: String.t(),
    web_page_parameters: Map.t(),
    pages_group: PagesGroup.t(),
    inserted_at: DateTime.t(),
    updated_at: DateTime.t()
  }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "gap_pages" do
    field :title, :string
    field :web_page_url, :string
    field :api_url, :string
    field :web_page_parameters, :map

    belongs_to :pages_group, PagesGroup

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gap_page, attrs) do
    gap_page
    |> cast(attrs, [:title, :web_page_url, :pages_group_id])
    |> validate_required([:title, :web_page_url, :pages_group_id])
    |> validate_length(:title, max: 255)
    |> unique_constraint(:title, name: :gap_pages_group_id_title_index, message: "Title must be unique for this pages group")
    |> foreign_key_constraint(:pages_group_id)
    |> extract_web_page_parameters()
  end

  def changeset_build_api_url(%Ecto.Changeset{data: %__MODULE__{}} = changeset) do
    api_url = ApiUrlBuilder.build_api_url(changeset)
    put_change(changeset, :api_url, api_url)
  end

  defp extract_web_page_parameters(changeset) do
    case changeset do
      %Changeset{changes: %{web_page_url: web_page_url}} ->
        %{query: query, fragment: fragment} = web_page_url |> URI.parse()
        params = %{} |> decode_and_merge(query) |> decode_and_merge(fragment)
        put_change(changeset, :web_page_parameters, params)
      _ ->
        changeset
    end
  end

  defp decode_and_merge(params, segment) when is_nil(segment), do: params
  defp decode_and_merge(params, segment), do: params |> Map.merge(URI.decode_query(segment))
end
