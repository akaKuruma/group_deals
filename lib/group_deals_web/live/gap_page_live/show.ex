defmodule GroupDealsWeb.GapPageLive.Show do
  use GroupDealsWeb, :live_view

  alias GroupDeals.Gap

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Gap page {@gap_page.id}
        <:subtitle>This is a gap_page record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/gap/pages_groups/#{@pages_group.id}/gap_pages"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/gap/pages_groups/#{@pages_group.id}/gap_pages/#{@gap_page}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit gap_page
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Title">{@gap_page.title}</:item>
        <:item title="Web page url">{@gap_page.web_page_url}</:item>
        <:item title="Api url">{@gap_page.api_url}</:item>
        <:item title="Pages group">{@gap_page.pages_group_id}</:item>
        <:item title="Web Page Parameters">
          <%= unless is_nil(@gap_page.web_page_parameters) or Enum.empty?(@gap_page.web_page_parameters) do %>
            <dl class="mt-2 space-y-1">
              <%= for {key, value} <- @gap_page.web_page_parameters do %>
                <div class="flex gap-2">
                  <dt class="font-semibold">{inspect(key)}</dt>
                  <dd>{inspect(value)}</dd>
                </div>
              <% end %>
            </dl>
          <% end %>
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    pages_group = Gap.get_pages_group!(params["pages_group_id"])
    gap_page = Gap.get_group_page!(pages_group.id, params["id"])

    {:ok,
     socket
     |> assign(:page_title, "Show Gap page")
     |> assign(:pages_group, pages_group)
     |> assign(:gap_page, gap_page)}
  end
end
