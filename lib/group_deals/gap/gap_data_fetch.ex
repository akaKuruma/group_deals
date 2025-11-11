defmodule GroupDeals.Gap.GapDataFetch do
  use Ecto.Schema
  import Ecto.Changeset
  alias GroupDeals.Gap.PagesGroup

  @type t :: %__MODULE__{
          id: binary,
          pages_group_id: binary,
          pages_group: PagesGroup.t() | nil,
          status: atom,
          current_step: String.t() | nil,
          total_pages: integer,
          processed_pages: integer,
          total_products: integer,
          processed_products: integer,
          total_images: integer,
          processed_images: integer,
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
    :failed,
    :fetching_product_list,
    :fetching_product_page,
    :fetching_product_image,
    :generating_output,
    :succeeded
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "gap_data_fetches" do
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :current_step, :string
    field :total_pages, :integer, default: 0
    field :processed_pages, :integer, default: 0
    field :total_products, :integer, default: 0
    field :processed_products, :integer, default: 0
    field :total_images, :integer, default: 0
    field :processed_images, :integer, default: 0
    field :error_message, :string
    field :error_details, :map
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :folder_timestamp, :string

    belongs_to :pages_group, PagesGroup

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gap_data_fetch, attrs) do
    gap_data_fetch
    |> cast(attrs, [
      :pages_group_id,
      :status,
      :current_step,
      :total_pages,
      :processed_pages,
      :total_products,
      :processed_products,
      :total_images,
      :processed_images,
      :error_message,
      :error_details,
      :started_at,
      :completed_at,
      :folder_timestamp
    ])
    |> validate_required([:pages_group_id, :status])
    |> foreign_key_constraint(:pages_group_id)
    |> unique_constraint(:pages_group_id,
      name: :gap_data_fetches_active_per_pages_group_index,
      message: "An active fetch already exists for this pages group"
    )
  end

  def statuses, do: @statuses

  def active_status?(status) do
    status not in [:failed, :succeeded]
  end
end
