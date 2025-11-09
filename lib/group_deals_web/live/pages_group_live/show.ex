defmodule GroupDealsWeb.PagesGroupLive.Show do
  use GroupDealsWeb, :live_view

  alias GroupDeals.Gap

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Pages group {@pages_group.id}
        <:subtitle>This is a pages_group record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/gap/pages_groups"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button
            variant="primary"
            navigate={~p"/gap/pages_groups/#{@pages_group}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Edit pages_group
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Title">{@pages_group.title}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Pages group")
     |> assign(:pages_group, Gap.get_pages_group!(id))}
  end
end
