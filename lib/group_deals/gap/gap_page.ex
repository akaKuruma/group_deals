defmodule GroupDeals.Gap.GapPage do
  use Ecto.Schema
  import Ecto.Changeset
  alias GroupDeals.Gap.PagesGroup

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
    |> cast(attrs, [:title, :web_page_url, :api_url, :web_page_parameters, :pages_group_id])
    |> validate_required([:title, :web_page_url, :api_url, :pages_group_id])
    |> validate_length(:title, max: 255)
    |> unique_constraint(:title, name: :gap_pages_group_id_title_index, message: "Title must be unique for this pages group")
    |> foreign_key_constraint(:pages_group_id)
  end
end
