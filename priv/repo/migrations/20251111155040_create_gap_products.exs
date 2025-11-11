defmodule GroupDeals.Repo.Migrations.CreateGapProducts do
  use Ecto.Migration

  def change do
    create table(:gap_products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :cc_id, :string, null: false
      add :style_id, :string, null: false
      add :style_name, :string
      add :cc_name, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:gap_products, [:cc_id])
    create index(:gap_products, [:style_id])
  end
end
