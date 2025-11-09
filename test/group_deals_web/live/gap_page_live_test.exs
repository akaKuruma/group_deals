defmodule GroupDealsWeb.GapPageLiveTest do
  use GroupDealsWeb.ConnCase

  import Phoenix.LiveViewTest
  import GroupDeals.GapFixtures

  @create_attrs %{
    title: "Page New Title",
    web_page_url: "https://www.gap.com/bruzinha/logo"
  }

  @update_attrs %{
    title: "Page Updated Title",
    web_page_url: "https://www.gap.com/bruzinha/updated-logo"
  }

  @invalid_attrs %{
    web_page_url: nil,
    title: nil
  }

  defp create_gap_page(_) do
    gap_page = gap_page_fixture()

    %{gap_page: gap_page, pages_group_id: gap_page.pages_group_id}
  end

  describe "Index" do
    setup [:create_gap_page]

    test "lists all gap_pages", %{conn: conn, gap_page: gap_page} do
      {:ok, _index_live, html} = live(conn, ~p"/gap/pages_groups/#{gap_page.pages_group_id}/gap_pages")

      assert html =~ "Listing Gap pages"
      assert html =~ gap_page.title
    end

    test "saves new gap_page", %{conn: conn, pages_group_id: pages_group_id} do

      {:ok, index_live, _html} = live(conn, ~p"/gap/pages_groups/#{pages_group_id}/gap_pages")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Gap page")
               |> render_click()
               |> follow_redirect(conn, ~p"/gap/pages_groups/#{pages_group_id}/gap_pages/new")

      assert render(form_live) =~ "New Gap page"

      assert form_live
             |> form("#gap_page-form", gap_page: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#gap_page-form", gap_page: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/gap/pages_groups/#{pages_group_id}/gap_pages")

      html = render(index_live)
      assert html =~ "Gap page created successfully"
      assert html =~ "Page New Title"
    end

    test "updates gap_page in listing", %{conn: conn, gap_page: gap_page} do
      {:ok, index_live, _html} = live(conn, ~p"/gap/pages_groups/#{gap_page.pages_group_id}/gap_pages")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#gap_pages-#{gap_page.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/gap/pages_groups/#{gap_page.pages_group_id}/gap_pages/#{gap_page}/edit")

      assert render(form_live) =~ "Edit Gap page"

      assert form_live
             |> form("#gap_page-form", gap_page: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#gap_page-form", gap_page: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/gap/pages_groups/#{gap_page.pages_group_id}/gap_pages")

      html = render(index_live)
      assert html =~ "Gap page updated successfully"
      assert html =~ "Page Updated Title"
    end

    test "deletes gap_page in listing", %{conn: conn, gap_page: gap_page} do
      {:ok, index_live, _html} = live(conn, ~p"/gap/pages_groups/#{gap_page.pages_group_id}/gap_pages")

      assert index_live |> element("#gap_pages-#{gap_page.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#gap_pages-#{gap_page.id}")
    end
  end

  describe "Show" do
    setup [:create_gap_page]

    test "displays gap_page", %{conn: conn, gap_page: gap_page} do
      {:ok, _show_live, html} = live(conn, ~p"/gap/pages_groups/#{gap_page.pages_group_id}/gap_pages/#{gap_page}")

      assert html =~ "Show Gap page"
      assert html =~ gap_page.web_page_url
    end

    test "updates gap_page and returns to show", %{conn: conn, gap_page: gap_page} do
      {:ok, show_live, _html} = live(conn, ~p"/gap/pages_groups/#{gap_page.pages_group_id}/gap_pages/#{gap_page}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/gap/pages_groups/#{gap_page.pages_group_id}/gap_pages/#{gap_page}/edit?return_to=show")

      assert render(form_live) =~ "Edit Gap page"

      assert form_live
             |> form("#gap_page-form", gap_page: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#gap_page-form", gap_page: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/gap/pages_groups/#{gap_page.pages_group_id}/gap_pages/#{gap_page}")

      html = render(show_live)
      assert html =~ "Gap page updated successfully"
      assert html =~ "Page Updated Title"
      assert html =~ "https://api.gapfactory.com/commerce/search/products/v2/cc?brand=gapfs&amp;client_id=0&amp;enableDynamicPhoto=true&amp;ignoreInventory=false&amp;includeMarketingFlagsDetails=true&amp;locale=en_US&amp;market=us&amp;pageNumber=0&amp;pageSize=200&amp;session_id=0&amp;vendor=constructorio"
      assert html =~ "https://www.gap.com/bruzinha/updated-logo"
    end
  end
end
