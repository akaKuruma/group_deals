defmodule GroupDeals.Repo.Migrations.CreateGapPages do
  use Ecto.Migration

  def change do
    create table(:gap_pages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :web_page_url, :text, null: false
      add :api_url, :text, null: false
      add :web_page_parameters, :map
      add :pages_group_id, :binary

      timestamps(type: :utc_datetime)
    end

    create unique_index(:gap_pages, [:pages_group_id, :title], name: :gap_pages_group_id_title_index)
  end
end
