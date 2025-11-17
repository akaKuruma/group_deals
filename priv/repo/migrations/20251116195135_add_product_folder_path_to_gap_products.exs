defmodule GroupDeals.Repo.Migrations.AddProductFolderPathToGapProducts do
  use Ecto.Migration

  def change do
    alter table(:gap_products) do
      add :product_folder_path, :string,
        default: "/tmp/gap_site/products/missing_gap_product_id/",
        null: false
    end
  end
end
