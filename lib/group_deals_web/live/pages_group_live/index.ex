defmodule GroupDealsWeb.PagesGroupLive.Index do
  use GroupDealsWeb, :live_view

  alias GroupDeals.Gap
  alias GroupDeals.Gap.FetchCoordinator
  alias GroupDeals.Gap.GapDataFetch

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

        <:action :let={{_id, pages_group}}>
          <.link navigate={~p"/gap/pages_groups/#{pages_group.id}/gap_pages"}>
            Gap Pages
          </.link>
        </:action>

        <:action :let={{_id, pages_group}}>
          <.button
            phx-click="start_fetch"
            phx-value-id={pages_group.id}
            disabled={has_active_fetch?(pages_group)}
            variant={if has_active_fetch?(pages_group), do: nil, else: "primary"}
          >
            <.icon name="hero-arrow-down-tray" /> Fetch Data
          </.button>
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

  @impl true
  def handle_event("start_fetch", %{"id" => id}, socket) do
    pages_group = Gap.get_pages_group!(id)

    case FetchCoordinator.start_fetch(pages_group) do
      {:ok, _gap_data_fetch} ->
        {:noreply,
         socket
         |> put_flash(:info, "Fetch process started successfully")
         |> stream(:pages_groups, list_pages_groups(), reset: true)}

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

  defp list_pages_groups() do
    Gap.list_pages_groups()
  end

  defp has_active_fetch?(pages_group) do
    pages_group.gap_data_fetches
    |> Enum.any?(fn fetch -> GapDataFetch.active_status?(fetch.status) end)
  end
end
