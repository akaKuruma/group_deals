defmodule GroupDealsWeb.PagesGroupLiveTest do
  use GroupDealsWeb.ConnCase

  import Phoenix.LiveViewTest
  import GroupDeals.GapFixtures

  @create_attrs %{title: "some valid title"}
  @update_attrs %{title: "some valid updated title"}
  @invalid_attrs %{title: nil}
  defp create_pages_group(_) do
    pages_group = pages_group_fixture()

    %{pages_group: pages_group}
  end

  describe "Index" do
    setup [:create_pages_group]

    test "lists all pages_groups", %{conn: conn, pages_group: pages_group} do
      {:ok, _index_live, html} = live(conn, ~p"/gap/pages_groups")

      assert html =~ "Listing Pages groups"
      assert html =~ pages_group.title
    end

    test "displays Fetch Data button", %{conn: conn} do
      {:ok, index_live, html} = live(conn, ~p"/gap/pages_groups")

      assert html =~ "Fetch Data"
      assert has_element?(index_live, "button", "Fetch Data")
    end

    test "Fetch Data button is enabled when no active fetch exists", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/gap/pages_groups")

      button = element(index_live, "button[phx-click='start_fetch']")
      assert has_element?(button)
      refute render(button) =~ "disabled"
    end

    test "Fetch Data button is disabled when active fetch exists", %{
      conn: conn,
      pages_group: pages_group
    } do
      import GroupDeals.GapFixtures

      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :pending})

      {:ok, index_live, _html} = live(conn, ~p"/gap/pages_groups")

      button = element(index_live, "button[phx-click='start_fetch']")
      assert has_element?(button)
      assert render(button) =~ "disabled"
    end

    test "start_fetch event creates gap_data_fetch and shows success message", %{
      conn: conn,
      pages_group: pages_group
    } do
      {:ok, index_live, _html} = live(conn, ~p"/gap/pages_groups")

      index_live
      |> element("button[phx-click='start_fetch'][phx-value-id='#{pages_group.id}']")
      |> render_click()

      assert render(index_live) =~ "Fetch process started successfully"
    end

    test "start_fetch event shows error when active fetch exists", %{
      conn: conn,
      pages_group: pages_group
    } do
      import GroupDeals.GapFixtures

      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :pending})

      {:ok, index_live, _html} = live(conn, ~p"/gap/pages_groups")

      # Button should be disabled, so we trigger the event directly
      send(index_live.pid, %Phoenix.Socket.Message{
        topic: "lv:" <> index_live.id,
        event: "event",
        payload: %{
          "type" => "click",
          "event" => "start_fetch",
          "value" => %{"id" => pages_group.id}
        }
      })

      assert render(index_live) =~ "An active fetch process already exists"
    end

    test "saves new pages_group", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/gap/pages_groups")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Pages group")
               |> render_click()
               |> follow_redirect(conn, ~p"/gap/pages_groups/new")

      assert render(form_live) =~ "New Pages group"

      assert form_live
             |> form("#pages_group-form", pages_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#pages_group-form", pages_group: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/gap/pages_groups")

      html = render(index_live)
      assert html =~ "Pages group created successfully"
      assert html =~ "some title"
    end

    test "updates pages_group in listing", %{conn: conn, pages_group: pages_group} do
      {:ok, index_live, _html} = live(conn, ~p"/gap/pages_groups")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#pages_groups-#{pages_group.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/gap/pages_groups/#{pages_group}/edit")

      assert render(form_live) =~ "Edit Pages group"

      assert form_live
             |> form("#pages_group-form", pages_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#pages_group-form", pages_group: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/gap/pages_groups")

      html = render(index_live)
      assert html =~ "Pages group updated successfully"
      assert html =~ "some valid updated title"
    end

    test "deletes pages_group in listing", %{conn: conn, pages_group: pages_group} do
      {:ok, index_live, _html} = live(conn, ~p"/gap/pages_groups")

      assert index_live
             |> element("#pages_groups-#{pages_group.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#pages_groups-#{pages_group.id}")
    end
  end

  describe "Show" do
    setup [:create_pages_group]

    test "displays pages_group", %{conn: conn, pages_group: pages_group} do
      {:ok, _show_live, html} = live(conn, ~p"/gap/pages_groups/#{pages_group}")

      assert html =~ "Show Pages group"
      assert html =~ pages_group.title
    end

    test "displays Fetch Data button", %{conn: conn, pages_group: pages_group} do
      {:ok, show_live, html} = live(conn, ~p"/gap/pages_groups/#{pages_group}")

      assert html =~ "Fetch Data"
      assert has_element?(show_live, "button", "Fetch Data")
    end

    test "Fetch Data button is enabled when no active fetch exists", %{
      conn: conn,
      pages_group: pages_group
    } do
      {:ok, show_live, _html} = live(conn, ~p"/gap/pages_groups/#{pages_group}")

      button = element(show_live, "button[phx-click='start_fetch']")
      assert has_element?(button)
      refute render(button) =~ "disabled"
    end

    test "Fetch Data button is disabled when active fetch exists", %{
      conn: conn,
      pages_group: pages_group
    } do
      import GroupDeals.GapFixtures

      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :pending})

      {:ok, show_live, _html} = live(conn, ~p"/gap/pages_groups/#{pages_group}")

      button = element(show_live, "button[phx-click='start_fetch']")
      assert has_element?(button)
      assert render(button) =~ "disabled"
    end

    test "start_fetch event creates gap_data_fetch and shows success message", %{
      conn: conn,
      pages_group: pages_group
    } do
      {:ok, show_live, _html} = live(conn, ~p"/gap/pages_groups/#{pages_group}")

      show_live
      |> element("button[phx-click='start_fetch'][phx-value-id='#{pages_group.id}']")
      |> render_click()

      assert render(show_live) =~ "Fetch process started successfully"
    end

    test "start_fetch event shows error when active fetch exists", %{
      conn: conn,
      pages_group: pages_group
    } do
      import GroupDeals.GapFixtures

      gap_data_fetch_fixture(%{pages_group_id: pages_group.id, status: :pending})

      {:ok, show_live, _html} = live(conn, ~p"/gap/pages_groups/#{pages_group}")

      # Button should be disabled, so we trigger the event directly
      send(show_live.pid, %Phoenix.Socket.Message{
        topic: "lv:" <> show_live.id,
        event: "event",
        payload: %{
          "type" => "click",
          "event" => "start_fetch",
          "value" => %{"id" => pages_group.id}
        }
      })

      assert render(show_live) =~ "An active fetch process already exists"
    end

    test "updates pages_group and returns to show", %{conn: conn, pages_group: pages_group} do
      {:ok, show_live, _html} = live(conn, ~p"/gap/pages_groups/#{pages_group}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/gap/pages_groups/#{pages_group}/edit?return_to=show")

      assert render(form_live) =~ "Edit Pages group"

      assert form_live
             |> form("#pages_group-form", pages_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#pages_group-form", pages_group: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/gap/pages_groups/#{pages_group}")

      html = render(show_live)
      assert html =~ "Pages group updated successfully"
      assert html =~ "some valid updated title"
    end
  end
end
