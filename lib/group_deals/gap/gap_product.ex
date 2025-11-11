defmodule GroupDeals.Gap.GapProduct do
  use Ecto.Schema
  import Ecto.Changeset
  alias GroupDeals.Gap.GapProductData

  @type t :: %__MODULE__{
          id: binary,
          cc_id: String.t(),
          style_id: String.t(),
          style_name: String.t() | nil,
          cc_name: String.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "gap_products" do
    field :cc_id, :string
    field :style_id, :string
    field :style_name, :string
    field :cc_name, :string

    has_many :gap_product_data, GapProductData, foreign_key: :product_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gap_product, attrs) do
    gap_product
    |> cast(attrs, [:cc_id, :style_id, :style_name, :cc_name])
    |> validate_required([:cc_id, :style_id])
    |> unique_constraint(:cc_id)
  end
end
