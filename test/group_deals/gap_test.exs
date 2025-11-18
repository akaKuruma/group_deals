defmodule GroupDeals.GapTest do
  use GroupDeals.DataCase

  alias GroupDeals.Gap

  describe "pages_groups" do
    alias GroupDeals.Gap.PagesGroup

    import GroupDeals.GapFixtures

    @invalid_attrs %{title: nil}

    test "list_pages_groups/0 returns all pages_groups" do
      pages_group = pages_group_fixture()
      [loaded_pages_group] = Gap.list_pages_groups()
      assert loaded_pages_group.id == pages_group.id
      assert loaded_pages_group.title == pages_group.title
    end

    test "get_pages_group!/1 returns the pages_group with given id" do
      pages_group = pages_group_fixture()
      loaded_pages_group = Gap.get_pages_group!(pages_group.id)
      assert loaded_pages_group.id == pages_group.id
      assert loaded_pages_group.title == pages_group.title
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

      assert {:ok, %PagesGroup{} = pages_group} =
               Gap.update_pages_group(pages_group, update_attrs)

      assert pages_group.title == "some updated title"
    end

    test "update_pages_group/2 with invalid data returns error changeset" do
      pages_group = pages_group_fixture()
      assert {:error, %Ecto.Changeset{}} = Gap.update_pages_group(pages_group, @invalid_attrs)
      loaded_pages_group = Gap.get_pages_group!(pages_group.id)
      assert loaded_pages_group.id == pages_group.id
      assert loaded_pages_group.title == pages_group.title
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

    @invalid_attrs %{
      api_url: nil,
      web_page_url: nil,
      web_page_parameters: nil,
      pages_group_id: nil
    }

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

      valid_attrs = %{
        title: "some title",
        api_url: "some api_url",
        web_page_url: "some web_page_url",
        web_page_parameters: %{}
      }

      assert {:ok, %GapPage{} = gap_page} = Gap.create_gap_page(pages_group, valid_attrs)
      assert gap_page.title == "some title"
      assert gap_page.web_page_url == "some web_page_url"
      assert gap_page.web_page_parameters == %{}
      assert gap_page.pages_group_id == pages_group.id
      refute is_nil(gap_page.api_url)
    end

    test "create_gap_page/1 with invalid data returns error changeset" do
      pages_group = pages_group_fixture()
      assert {:error, %Ecto.Changeset{}} = Gap.create_gap_page(pages_group, @invalid_attrs)
    end

    test "update_gap_page/2 with valid data updates the gap_page" do
      gap_page = gap_page_fixture()

      update_attrs = %{
        api_url: "some updated api_url",
        web_page_url: "some updated web_page_url",
        web_page_parameters: %{}
      }

      assert {:ok, %GapPage{} = gap_page} = Gap.update_gap_page(gap_page, update_attrs)
      refute is_nil(gap_page.api_url)
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

  describe "gap_group_products_fetch_statuses" do
    alias GroupDeals.Gap.GapGroupProductsFetchStatus

    import GroupDeals.GapFixtures

    @invalid_attrs %{pages_group_id: nil, status: nil}

    test "get_active_fetch_for_pages_group/1 returns nil when no active fetch exists" do
      pages_group = pages_group_fixture()
      assert Gap.get_active_fetch_status_for_pages_group(pages_group.id) == nil
    end

    test "get_active_fetch_for_pages_group/1 returns active fetch when one exists" do
      pages_group = pages_group_fixture()
      gap_data_fetch = gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :pending})

      assert Gap.get_active_fetch_status_for_pages_group(pages_group.id).id == gap_data_fetch.id
    end

    test "get_active_fetch_for_pages_group/1 returns nil for failed fetch" do
      pages_group = pages_group_fixture()
      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :failed})

      assert Gap.get_active_fetch_status_for_pages_group(pages_group.id) == nil
    end

    test "get_active_fetch_for_pages_group/1 returns nil for succeeded fetch" do
      pages_group = pages_group_fixture()
      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :succeeded})

      assert Gap.get_active_fetch_status_for_pages_group(pages_group.id) == nil
    end

    test "get_active_fetch_for_pages_group/1 returns most recent active fetch" do
      pages_group = pages_group_fixture()
      old_fetch = gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :failed})
      new_fetch = gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :pending})

      active_fetch = Gap.get_active_fetch_status_for_pages_group(pages_group.id)
      assert active_fetch.id == new_fetch.id
      refute active_fetch.id == old_fetch.id
    end

    test "create_gap_data_fetch/1 with valid data creates a gap_data_fetch" do
      pages_group = pages_group_fixture()

      valid_attrs = %{
        pages_group_id: pages_group.id,
        status: :pending,
        folder_timestamp: "20241111000000"
      }

      assert {:ok, %GapGroupProductsFetchStatus{} = gap_group_products_fetch_status} = Gap.create_gap_group_products_fetch_status(valid_attrs)
      assert gap_group_products_fetch_status.pages_group_id == pages_group.id
      assert gap_group_products_fetch_status.status == :pending
      assert gap_group_products_fetch_status.folder_timestamp == "20241111000000"
    end

    test "create_gap_data_fetch/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gap.create_gap_group_products_fetch_status(@invalid_attrs)
    end

    test "create_gap_data_fetch/1 enforces unique active fetch per pages_group" do
      pages_group = pages_group_fixture()
      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :pending})

      attrs = %{
        pages_group_id: pages_group.id,
        status: :pending,
        folder_timestamp: "20241111000001"
      }

      assert {:error, %Ecto.Changeset{errors: errors}} = Gap.create_gap_group_products_fetch_status(attrs)
      assert Keyword.has_key?(errors, :pages_group_id)
      {message, _opts} = Keyword.get(errors, :pages_group_id)
      assert message == "An active fetch already exists for this pages group"
    end

    test "create_gap_data_fetch/1 allows multiple fetches when previous ones are failed" do
      pages_group = pages_group_fixture()
      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :failed})

      attrs = %{
        pages_group_id: pages_group.id,
        status: :pending,
        folder_timestamp: "20241111000001"
      }

      assert {:ok, %GapGroupProductsFetchStatus{}} = Gap.create_gap_group_products_fetch_status(attrs)
    end

    test "create_gap_data_fetch/1 allows multiple fetches when previous ones are succeeded" do
      pages_group = pages_group_fixture()
      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :succeeded})

      attrs = %{
        pages_group_id: pages_group.id,
        status: :pending,
        folder_timestamp: "20241111000001"
      }

      assert {:ok, %GapGroupProductsFetchStatus{}} = Gap.create_gap_group_products_fetch_status(attrs)
    end

    test "list_pages_groups/0 preloads gap_data_fetches" do
      pages_group = pages_group_fixture()
      gap_data_fetch_fixture(%{pages_group_id: pages_group.id})

      [loaded_pages_group] = Gap.list_pages_groups()
      assert Ecto.assoc_loaded?(loaded_pages_group.gap_group_products_fetch_statuses)
      assert length(loaded_pages_group.gap_group_products_fetch_statuses) == 1
    end

    test "get_pages_group!/1 preloads gap_data_fetches" do
      pages_group = pages_group_fixture()
      gap_data_fetch_fixture(%{pages_group_id: pages_group.id})

      loaded_pages_group = Gap.get_pages_group!(pages_group.id)
      assert Ecto.assoc_loaded?(loaded_pages_group.gap_group_products_fetch_statuses)
      assert length(loaded_pages_group.gap_group_products_fetch_statuses) == 1
    end
  end
end
