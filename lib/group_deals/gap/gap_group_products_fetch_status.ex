defmodule GroupDeals.Gap.GapGroupProductsFetchStatus do
  use Ecto.Schema
  import Ecto.Changeset
  alias GroupDeals.Gap.PagesGroup
  alias GroupDeals.Gap.GapProductData

  @type t :: %__MODULE__{
          id: binary,
          pages_group_id: binary,
          pages_group: PagesGroup.t() | nil,
          status: atom,
          product_list_page_total: integer,
          product_list_page_succeeded_count: integer,
          product_list_page_failed_count: integer,
          products_total: integer,
          product_page_fetched_count: integer,
          product_page_parsed_count: integer,
          product_image_downloaded_count: integer,
          error_message: String.t() | nil,
          error_details: map | nil,
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          folder_timestamp: String.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @statuses [
    :pending,
    :processing,
    :succeeded,
    :failed
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "gap_group_products_fetch_statuses" do
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :product_list_page_total, :integer, default: 0
    field :product_list_page_succeeded_count, :integer, default: 0
    field :product_list_page_failed_count, :integer, default: 0
    field :products_total, :integer, default: 0
    field :product_page_fetched_count, :integer, default: 0
    field :product_page_parsed_count, :integer, default: 0
    field :product_image_downloaded_count, :integer, default: 0
    field :error_message, :string
    field :error_details, :map
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :folder_timestamp, :string

    belongs_to :pages_group, PagesGroup

    has_many :gap_product_data, GapProductData

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gap_group_products_fetch_status, attrs) do
    gap_group_products_fetch_status
    |> cast(attrs, [
      :pages_group_id,
      :status,
      :product_list_page_total,
      :product_list_page_succeeded_count,
      :product_list_page_failed_count,
      :products_total,
      :product_page_fetched_count,
      :product_page_parsed_count,
      :product_image_downloaded_count,
      :error_message,
      :error_details,
      :started_at,
      :completed_at,
      :folder_timestamp
    ])
    |> validate_required([:pages_group_id, :status])
    |> foreign_key_constraint(:pages_group_id)
    |> unique_constraint(:pages_group_id,
      name: :gap_group_products_fetch_statuses_active_per_pages_group_index,
      message: "An active fetch already exists for this pages group"
    )
  end

  def statuses, do: @statuses

  def active_status?(status) do
    status in [:pending, :processing]
  end

  @doc """
  Calculates the progress percentage for product list pages.
  Returns 0 if total is 0 to avoid division by zero.
  """
  def progress_percentage(%__MODULE__{
        product_list_page_total: total,
        product_list_page_succeeded_count: succeeded,
        product_list_page_failed_count: failed
      }) do
    if total > 0 do
      processed = succeeded + failed
      round(processed / total * 100)
    else
      0
    end
  end

  @doc """
  Checks if the fetch process is finished.
  Returns true if all product list pages are processed (succeeded or failed)
  and all products have been processed.
  """
  def finished?(%__MODULE__{
        product_list_page_total: page_total,
        product_list_page_succeeded_count: page_succeeded,
        product_list_page_failed_count: page_failed,
        products_total: products_total,
        product_page_fetched_count: fetched_count,
        product_page_parsed_count: parsed_count,
        product_image_downloaded_count: image_count
      }) do
    pages_complete = page_succeeded + page_failed >= page_total

    products_complete =
      fetched_count >= products_total and parsed_count >= products_total and
        image_count >= products_total

    pages_complete and products_complete
  end
end
