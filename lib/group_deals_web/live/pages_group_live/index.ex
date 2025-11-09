defmodule GroupDealsWeb.PagesGroupLive.Index do
  use GroupDealsWeb, :live_view

  alias GroupDeals.Gap

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Pages groups
        <:actions>
          <.button variant="primary" navigate={~p"/gap/pages_groups/new"}>
            <.icon name="hero-plus" /> New Pages group
          </.button>
        </:actions>
      </.header>

      <.table
        id="pages_groups"
        rows={@streams.pages_groups}
        row_click={fn {_id, pages_group} -> JS.navigate(~p"/gap/pages_groups/#{pages_group}") end}
      >
        <:col :let={{_id, pages_group}} label="Title">{pages_group.title}</:col>
        <:action :let={{_id, pages_group}}>
          <div class="sr-only">
            <.link navigate={~p"/gap/pages_groups/#{pages_group}"}>Show</.link>
          </div>
          <.link navigate={~p"/gap/pages_groups/#{pages_group}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, pages_group}}>
          <.link
            phx-click={JS.push("delete", value: %{id: pages_group.id}) |> hide("##{id}")}
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
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Pages groups")
     |> stream(:pages_groups, list_pages_groups())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    pages_group = Gap.get_pages_group!(id)
    {:ok, _} = Gap.delete_pages_group(pages_group)

    {:noreply, stream_delete(socket, :pages_groups, pages_group)}
  end

  defp list_pages_groups() do
    Gap.list_pages_groups()
  end
end
