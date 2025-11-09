defmodule GroupDealsWeb.PagesGroupLive.Form do
  use GroupDealsWeb, :live_view

  alias GroupDeals.Gap
  alias GroupDeals.Gap.PagesGroup

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage pages_group records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="pages_group-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="text" label="Title" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Pages group</.button>
          <.button navigate={return_path(@return_to, @pages_group)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    pages_group = Gap.get_pages_group!(id)

    socket
    |> assign(:page_title, "Edit Pages group")
    |> assign(:pages_group, pages_group)
    |> assign(:form, to_form(Gap.change_pages_group(pages_group)))
  end

  defp apply_action(socket, :new, _params) do
    pages_group = %PagesGroup{}

    socket
    |> assign(:page_title, "New Pages group")
    |> assign(:pages_group, pages_group)
    |> assign(:form, to_form(Gap.change_pages_group(pages_group)))
  end

  @impl true
  def handle_event("validate", %{"pages_group" => pages_group_params}, socket) do
    changeset = Gap.change_pages_group(socket.assigns.pages_group, pages_group_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"pages_group" => pages_group_params}, socket) do
    save_pages_group(socket, socket.assigns.live_action, pages_group_params)
  end

  defp save_pages_group(socket, :edit, pages_group_params) do
    case Gap.update_pages_group(socket.assigns.pages_group, pages_group_params) do
      {:ok, pages_group} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pages group updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, pages_group))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_pages_group(socket, :new, pages_group_params) do
    case Gap.create_pages_group(pages_group_params) do
      {:ok, pages_group} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pages group created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, pages_group))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _pages_group), do: ~p"/gap/pages_groups"
  defp return_path("show", pages_group), do: ~p"/gap/pages_groups/#{pages_group}"
end
