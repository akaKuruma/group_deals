defmodule GroupDealsWeb.GapPageLive.Form do
  use GroupDealsWeb, :live_view

  alias GroupDeals.Gap
  alias GroupDeals.Gap.GapPage

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage gap_page records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="gap_page-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:web_page_url]} type="text" label="Web page url" />
        <.input field={@form[:api_url]} type="text" label="Api url" />

        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Gap page</.button>
          <.button navigate={return_path(@return_to, @pages_group.id, @gap_page)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    pages_group = Gap.get_pages_group!(params["pages_group_id"])

    {:ok,
     socket
     |> assign(:pages_group, pages_group)
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    gap_page = Gap.get_group_page!(socket.assigns.pages_group.id, id)

    socket
    |> assign(:page_title, "Edit Gap page")
    |> assign(:gap_page, gap_page)
    |> assign(:form, to_form(Gap.change_gap_page(gap_page)))
  end

  defp apply_action(socket, :new, _params) do
    gap_page = %GapPage{}

    socket
    |> assign(:page_title, "New Gap page")
    |> assign(:gap_page, gap_page)
    |> assign(:form, to_form(Gap.change_gap_page(gap_page)))
  end

  @impl true
  def handle_event("validate", %{"gap_page" => gap_page_params}, socket) do
    changeset = Gap.change_gap_page(socket.assigns.gap_page, gap_page_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"gap_page" => gap_page_params}, socket) do
    save_gap_page(socket, socket.assigns.live_action, gap_page_params)
  end

  defp save_gap_page(socket, :edit, gap_page_params) do
    case Gap.update_gap_page(socket.assigns.gap_page, gap_page_params) do
      {:ok, gap_page} ->
        {:noreply,
         socket
         |> put_flash(:info, "Gap page updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, socket.assigns.pages_group.id, gap_page))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_gap_page(socket, :new, gap_page_params) do
    case Gap.create_gap_page(socket.assigns.pages_group, gap_page_params) do
      {:ok, gap_page} ->
        {:noreply,
         socket
         |> put_flash(:info, "Gap page created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, socket.assigns.pages_group.id, gap_page))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", pages_group_id, _gap_page), do: ~p"/gap/pages_groups/#{pages_group_id}/gap_pages"
  defp return_path("show", pages_group_id, gap_page), do: ~p"/gap/pages_groups/#{pages_group_id}/gap_pages/#{gap_page}"
  defp return_path("edit", pages_group_id, gap_page), do: ~p"/gap/pages_groups/#{pages_group_id}/gap_pages/#{gap_page}/edit"
end
