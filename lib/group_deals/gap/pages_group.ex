defmodule GroupDeals.Gap.PagesGroup do
  use Ecto.Schema
  import Ecto.Changeset
  alias GroupDeals.Gap.GapPage
  alias GroupDeals.Gap.GapDataFetch

  @type t :: %__MODULE__{
          id: binary,
          title: String.t(),
          gap_pages: list(GapPage.t()),
          gap_data_fetches: list(GapDataFetch.t()),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "pages_groups" do
    field :title, :string

    has_many :gap_pages, GapPage
    has_many :gap_data_fetches, GroupDeals.Gap.GapDataFetch

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pages_group, attrs) do
    pages_group
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> validate_length(:title, max: 255)
    |> unique_constraint(:title)
  end
end
