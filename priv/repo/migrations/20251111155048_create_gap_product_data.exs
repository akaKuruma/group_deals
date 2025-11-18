defmodule GroupDeals.Repo.Migrations.CreateGapProductData do
  use Ecto.Migration

  def change do
    create table(:gap_product_data, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_id, references(:gap_products, type: :binary_id, on_delete: :delete_all)

      add :gap_group_products_fetch_status_id,
          references(:gap_group_products_fetch_statuses, type: :binary_id, on_delete: :delete_all)

      add :folder_timestamp, :string, null: false
      add :api_image_paths, {:array, :string}, default: []
      add :html_file_path, :string
      add :parsed_data, :map
      add :image_paths, {:array, :string}

      timestamps(type: :utc_datetime)
    end

    create index(:gap_product_data, [:gap_group_products_fetch_status_id])
    create index(:gap_product_data, [:product_id])
  end
end
