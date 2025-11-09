defmodule GroupDealsWeb.GapPageLive.Index do
  use GroupDealsWeb, :live_view

  alias GroupDeals.Gap

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Gap pages
        <:actions>
          <.button variant="primary" navigate={~p"/gap/pages_groups/#{@pages_group_id}/gap_pages/new"}>
            <.icon name="hero-plus" /> New Gap page
          </.button>
        </:actions>
      </.header>

      <.table
        id="gap_pages"
        rows={@streams.gap_pages}
        row_click={
          fn {_id, gap_page} ->
            JS.navigate(~p"/gap/pages_groups/#{@pages_group_id}/gap_pages/#{gap_page}")
          end
        }
      >
        <:col :let={{_id, gap_page}} label="Title">{gap_page.title}</:col>
        <:action :let={{_id, gap_page}}>
          <div class="sr-only">
            <.link navigate={~p"/gap/pages_groups/#{@pages_group_id}/gap_pages/#{gap_page}"}>
              Show
            </.link>
          </div>
          <.link navigate={~p"/gap/pages_groups/#{@pages_group_id}/gap_pages/#{gap_page}/edit"}>
            Edit
          </.link>
        </:action>
        <:action :let={{id, gap_page}}>
          <.link
            phx-click={JS.push("delete", value: %{id: gap_page.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Gap pages")
     |> assign(:pages_group_id, params["pages_group_id"])
     |> stream(:gap_pages, Gap.list_group_pages(params["pages_group_id"]))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    gap_page = Gap.get_gap_page!(id)
    {:ok, _} = Gap.delete_gap_page(gap_page)

    {:noreply, stream_delete(socket, :gap_pages, gap_page)}
  end
end
