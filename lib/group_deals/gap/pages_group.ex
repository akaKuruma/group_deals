defmodule GroupDeals.Gap.PagesGroup do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "pages_groups" do
    field :title, :string

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
