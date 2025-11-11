defmodule GroupDealsWeb.PagesGroupLive.Show do
  use GroupDealsWeb, :live_view

  alias GroupDeals.Gap
  alias GroupDeals.Gap.FetchCoordinator
  alias GroupDeals.Gap.GapDataFetch

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
            phx-click="start_fetch"
            phx-value-id={@pages_group.id}
            disabled={has_active_fetch?(@pages_group)}
            variant={if has_active_fetch?(@pages_group), do: nil, else: "primary"}
          >
            <.icon name="hero-arrow-down-tray" /> Fetch Data
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

  @impl true
  def handle_event("start_fetch", %{"id" => id}, socket) do
    pages_group = Gap.get_pages_group!(id)

    case FetchCoordinator.start_fetch(pages_group) do
      {:ok, _gap_data_fetch} ->
        {:noreply,
         socket
         |> put_flash(:info, "Fetch process started successfully")
         |> assign(:pages_group, Gap.get_pages_group!(id))}

      {:error, :active_fetch_exists} ->
        {:noreply,
         socket
         |> put_flash(:error, "An active fetch process already exists for this pages group")}

      {:error, changeset} ->
        error_message =
          case changeset.errors do
            [{:pages_group_id, {message, _}}] -> message
            _ -> "Failed to start fetch process"
          end

        {:noreply, put_flash(socket, :error, error_message)}
    end
  end

  defp has_active_fetch?(pages_group) do
    pages_group.gap_data_fetches
    |> Enum.any?(fn fetch -> GapDataFetch.active_status?(fetch.status) end)
  end
end
