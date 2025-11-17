defmodule GroupDeals.Repo.Migrations.AddPageFetchStatusToGapProductData do
  use Ecto.Migration

  def change do
    alter table(:gap_product_data) do
      add :page_fetch_status, :string, default: "pending", null: false
      add :product_page_url, :string
    end

    create index(:gap_product_data, [:gap_data_fetch_id, :page_fetch_status])
  end
end
