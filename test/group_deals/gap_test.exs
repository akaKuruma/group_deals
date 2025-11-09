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

  describe "gap_pages" do
    alias GroupDeals.Gap.GapPage

    import GroupDeals.GapFixtures

    @invalid_attrs %{api_url: nil, web_page_url: nil, web_page_parameters: nil, pages_group_id: nil}

    test "list_gap_pages/0 returns all gap_pages" do
      gap_page = gap_page_fixture()
      assert Gap.list_gap_pages() == [gap_page]
    end

    test "get_gap_page!/1 returns the gap_page with given id" do
      gap_page = gap_page_fixture()
      assert Gap.get_gap_page!(gap_page.id) == gap_page
    end

    test "create_gap_page/1 with valid data creates a gap_page" do
      pages_group = pages_group_fixture()
      valid_attrs = %{title: "some title", api_url: "some api_url", web_page_url: "some web_page_url", web_page_parameters: %{}}

      assert {:ok, %GapPage{} = gap_page} = Gap.create_gap_page(pages_group, valid_attrs)
      assert gap_page.title == "some title"
      assert gap_page.api_url == "some api_url"
      assert gap_page.web_page_url == "some web_page_url"
      assert gap_page.web_page_parameters == %{}
      assert gap_page.pages_group_id == pages_group.id
    end

    test "create_gap_page/1 with invalid data returns error changeset" do
      pages_group = pages_group_fixture()
      assert {:error, %Ecto.Changeset{}} = Gap.create_gap_page(pages_group, @invalid_attrs)
    end

    test "update_gap_page/2 with valid data updates the gap_page" do
      gap_page = gap_page_fixture()
      update_attrs = %{api_url: "some updated api_url", web_page_url: "some updated web_page_url", web_page_parameters: %{}}

      assert {:ok, %GapPage{} = gap_page} = Gap.update_gap_page(gap_page, update_attrs)
      assert gap_page.api_url == "some updated api_url"
      assert gap_page.web_page_url == "some updated web_page_url"
      assert gap_page.web_page_parameters == %{}
      assert gap_page.pages_group_id == gap_page.pages_group_id
    end

    test "update_gap_page/2 with invalid data returns error changeset" do
      gap_page = gap_page_fixture()
      assert {:error, %Ecto.Changeset{}} = Gap.update_gap_page(gap_page, @invalid_attrs)
      assert gap_page == Gap.get_gap_page!(gap_page.id)
    end

    test "delete_gap_page/1 deletes the gap_page" do
      gap_page = gap_page_fixture()
      assert {:ok, %GapPage{}} = Gap.delete_gap_page(gap_page)
      assert_raise Ecto.NoResultsError, fn -> Gap.get_gap_page!(gap_page.id) end
    end

    test "change_gap_page/1 returns a gap_page changeset" do
      gap_page = gap_page_fixture()
      assert %Ecto.Changeset{} = Gap.change_gap_page(gap_page)
    end
  end
end
