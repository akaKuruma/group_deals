defmodule GroupDealsWeb.PagesGroupLive.Show do
  use GroupDealsWeb, :live_view

  alias GroupDeals.Gap
  alias GroupDeals.Gap.FetchCoordinator
  alias GroupDeals.Gap.GapGroupProductsFetchStatus

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Pages group {@pages_group.title}
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

        <:item title="Statuses">
          <%= if active_fetch = get_active_fetch?(@pages_group) do %>
            <div class="space-y-2">
              <div class="flex items-center gap-2">
                <span class={["badge", "badge-#{status_badge_class(active_fetch.status)}"]}>
                  {String.capitalize(to_string(active_fetch.status))}
                </span>
              </div>

              <div class="text-sm space-y-1">
                <div>Progress: {GapGroupProductsFetchStatus.progress_percentage(active_fetch)}%</div>
                <div>
                  Pages: {active_fetch.product_list_page_succeeded_count}/{active_fetch.product_list_page_total}
                </div>
                <div>
                  Products: {active_fetch.product_page_fetched_count}/{active_fetch.products_total}
                </div>
                <div>
                  Parsed: {active_fetch.product_page_parsed_count}/{active_fetch.products_total}
                </div>
                <div>
                  Images: {active_fetch.product_image_downloaded_count}/{active_fetch.products_total}
                </div>
              </div>
            </div>
          <% end %>
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    pages_group = Gap.get_pages_group!(id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(GroupDeals.PubSub, "pages_group:#{id}:fetch_status")
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Pages group")
     |> assign(:pages_group, pages_group)}
  end

  @impl true
  def handle_event("start_fetch", %{"id" => id}, socket) do
    pages_group = Gap.get_pages_group!(id)

    case FetchCoordinator.start_fetch(pages_group) do
      {:ok, _gap_group_products_fetch_status} ->
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

  @impl true
  def handle_info({:fetch_status_updated, _updated_status}, socket) do
    # Reload the pages group to get the latest fetch status
    pages_group = Gap.get_pages_group!(socket.assigns.pages_group.id)
    {:noreply, assign(socket, :pages_group, pages_group)}
  end

  defp has_active_fetch?(pages_group) do
    pages_group.gap_group_products_fetch_statuses
    |> Enum.any?(fn fetch -> GapGroupProductsFetchStatus.active_status?(fetch.status) end)
  end

  defp get_active_fetch?(pages_group) do
    pages_group.gap_group_products_fetch_statuses
    |> Enum.find(fn fetch -> GapGroupProductsFetchStatus.active_status?(fetch.status) end)
  end

  defp status_badge_class(:pending), do: "warning"
  defp status_badge_class(:processing), do: "info"
  defp status_badge_class(:succeeded), do: "success"
  defp status_badge_class(:failed), do: "error"
end
