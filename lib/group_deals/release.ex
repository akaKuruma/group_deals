defmodule GroupDeals.Release do
  @moduledoc """
  Used for executing DB release tasks from within a release.

  ## Examples

      # Run migrations
      bin/group_deals eval "GroupDeals.Release.migrate()"

      # Rollback a migration
      bin/group_deals eval "GroupDeals.Release.rollback(GroupDeals.Repo, 20230101000000)"

      # Seed the database
      bin/group_deals eval "GroupDeals.Release.seed()"
  """

  @app :group_deals

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed do
    load_app()

    for repo <- repos() do
      seed_script = Application.app_dir(@app, "priv/repo/seeds.exs")

      if File.exists?(seed_script) do
        {:ok, _, _} =
          Ecto.Migrator.with_repo(repo, fn _repo ->
            Code.eval_file(seed_script)
          end)
      end
    end
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
