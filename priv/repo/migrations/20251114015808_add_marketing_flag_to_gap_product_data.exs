defmodule GroupDeals.Repo.Migrations.AddMarketingFlagToGapProductData do
  use Ecto.Migration

  def change do
    alter table(:gap_product_data) do
      add :marketing_flag, :string
    end
  end
end
