defmodule GroupDeals.GapTest do
  use GroupDeals.DataCase

  alias GroupDeals.Gap

  describe "pages_groups" do
    alias GroupDeals.Gap.PagesGroup

    import GroupDeals.GapFixtures

    @invalid_attrs %{title: nil}

    test "list_pages_groups/0 returns all pages_groups" do
      pages_group = pages_group_fixture()
      assert Gap.list_pages_groups() == [pages_group]
    end

    test "get_pages_group!/1 returns the pages_group with given id" do
      pages_group = pages_group_fixture()
      assert Gap.get_pages_group!(pages_group.id) == pages_group
    end

    test "create_pages_group/1 with valid data creates a pages_group" do
      valid_attrs = %{title: "some title"}

      assert {:ok, %PagesGroup{} = pages_group} = Gap.create_pages_group(valid_attrs)
      assert pages_group.title == "some title"
    end

    test "create_pages_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gap.create_pages_group(@invalid_attrs)
    end

    test "update_pages_group/2 with valid data updates the pages_group" do
      pages_group = pages_group_fixture()
      update_attrs = %{title: "some updated title"}

      assert {:ok, %PagesGroup{} = pages_group} = Gap.update_pages_group(pages_group, update_attrs)
      assert pages_group.title == "some updated title"
    end

    test "update_pages_group/2 with invalid data returns error changeset" do
      pages_group = pages_group_fixture()
      assert {:error, %Ecto.Changeset{}} = Gap.update_pages_group(pages_group, @invalid_attrs)
      assert pages_group == Gap.get_pages_group!(pages_group.id)
    end

    test "delete_pages_group/1 deletes the pages_group" do
      pages_group = pages_group_fixture()
      assert {:ok, %PagesGroup{}} = Gap.delete_pages_group(pages_group)
      assert_raise Ecto.NoResultsError, fn -> Gap.get_pages_group!(pages_group.id) end
    end

    test "change_pages_group/1 returns a pages_group changeset" do
      pages_group = pages_group_fixture()
      assert %Ecto.Changeset{} = Gap.change_pages_group(pages_group)
    end
  end
end
