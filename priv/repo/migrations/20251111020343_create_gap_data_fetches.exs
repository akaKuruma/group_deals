defmodule GroupDeals.Repo.Migrations.CreateGapDataFetches do
  use Ecto.Migration

  def change do
    create table(:gap_data_fetches, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :pages_group_id, references(:pages_groups, type: :binary_id, on_delete: :delete_all)
      add :status, :string, null: false
      add :current_step, :string
      add :total_pages, :integer, default: 0
      add :processed_pages, :integer, default: 0
      add :total_products, :integer, default: 0
      add :processed_products, :integer, default: 0
      add :total_images, :integer, default: 0
      add :processed_images, :integer, default: 0
      add :error_message, :text
      add :error_details, :map
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :folder_timestamp, :string

      timestamps(type: :utc_datetime)
    end

    create index(:gap_data_fetches, [:pages_group_id])
    create index(:gap_data_fetches, [:status])

    # Partial unique index: only one active fetch per pages_group
    create unique_index(:gap_data_fetches, [:pages_group_id],
             where: "status NOT IN ('failed', 'succeeded')",
             name: :gap_data_fetches_active_per_pages_group_index
           )
  end
end
