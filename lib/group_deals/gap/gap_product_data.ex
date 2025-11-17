defmodule GroupDeals.Gap.GapProductData do
  use Ecto.Schema
  import Ecto.Changeset
  alias GroupDeals.Gap.GapProduct
  alias GroupDeals.Gap.GapDataFetch

  @type t :: %__MODULE__{
          id: binary,
          product_id: binary,
          product: GapProduct.t() | nil,
          gap_data_fetch_id: binary,
          gap_data_fetch: GapDataFetch.t() | nil,
          folder_timestamp: String.t(),
          api_image_paths: list(String.t()),
          html_file_path: String.t() | nil,
          parsed_data: map | nil,
          image_paths: list(String.t()) | nil,
          marketing_flag: String.t() | nil,
          page_fetch_status: :pending | :succeeded | :failed,
          product_page_url: String.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "gap_product_data" do
    field :folder_timestamp, :string
    field :api_image_paths, {:array, :string}, default: []
    field :html_file_path, :string
    field :parsed_data, :map
    field :image_paths, {:array, :string}
    field :marketing_flag, :string

    field :page_fetch_status, Ecto.Enum,
      values: [:pending, :succeeded, :failed],
      default: :pending

    field :product_page_url, :string

    belongs_to :product, GapProduct
    belongs_to :gap_data_fetch, GapDataFetch

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gap_product_data, attrs) do
    gap_product_data
    |> cast(attrs, [
      :product_id,
      :gap_data_fetch_id,
      :folder_timestamp,
      :api_image_paths,
      :html_file_path,
      :parsed_data,
      :image_paths,
      :marketing_flag,
      :page_fetch_status,
      :product_page_url
    ])
    |> validate_required([:product_id, :gap_data_fetch_id, :folder_timestamp])
    |> foreign_key_constraint(:product_id)
    |> foreign_key_constraint(:gap_data_fetch_id)
  end
end
