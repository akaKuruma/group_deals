defmodule GroupDeals.Gap.GapProduct do
  use Ecto.Schema
  import Ecto.Changeset
  alias GroupDeals.Gap.GapProductData

  @standard_product_folder_path "/tmp/gap_site/products/"

  @type t :: %__MODULE__{
          id: binary,
          cc_id: String.t(),
          style_id: String.t(),
          style_name: String.t() | nil,
          cc_name: String.t() | nil,
          product_folder_path: String.t(),
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
    field :product_folder_path, :string

    has_many :gap_product_data, GapProductData, foreign_key: :product_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gap_product, attrs) do
    gap_product
    |> cast(attrs, [:cc_id, :style_id, :style_name, :cc_name, :product_folder_path])
    |> validate_required([:cc_id, :style_id])
    |> generate_product_folder_path()
    |> validate_required([:product_folder_path])
    |> unique_constraint(:cc_id)
  end

  defp generate_product_folder_path(changeset) do
    case {get_field(changeset, :cc_id), get_field(changeset, :product_folder_path)} do
      {cc_id, nil} when not is_nil(cc_id) ->
        product_folder_path = Path.join([@standard_product_folder_path, cc_id]) <> "/"
        put_change(changeset, :product_folder_path, product_folder_path)

      _ ->
        changeset
    end
  end
end
