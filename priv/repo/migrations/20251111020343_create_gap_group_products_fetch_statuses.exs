defmodule GroupDeals.Repo.Migrations.CreateGapGroupProductsFetchStatuses do
  use Ecto.Migration

  def change do
    create table(:gap_group_products_fetch_statuses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :pages_group_id, references(:pages_groups, type: :binary_id, on_delete: :delete_all)
      add :status, :string, null: false
      add :product_list_page_total, :integer, default: 0
      add :product_list_page_succeeded_count, :integer, default: 0
      add :product_list_page_failed_count, :integer, default: 0
      add :products_total, :integer, default: 0
      add :product_page_fetched_count, :integer, default: 0
      add :product_page_parsed_count, :integer, default: 0
      add :product_image_downloaded_count, :integer, default: 0
      add :error_message, :text
      add :error_details, :map
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :folder_timestamp, :string

      timestamps(type: :utc_datetime)
    end

    create index(:gap_group_products_fetch_statuses, [:pages_group_id])
    create index(:gap_group_products_fetch_statuses, [:status])

    # Partial unique index: only one active fetch per pages_group
    create unique_index(:gap_group_products_fetch_statuses, [:pages_group_id],
             where: "status NOT IN ('failed', 'succeeded')",
             name: :gap_group_products_fetch_statuses_active_per_pages_group_index
           )
  end
end
