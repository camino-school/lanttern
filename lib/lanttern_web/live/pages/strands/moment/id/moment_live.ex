defmodule LantternWeb.MomentLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  # shared components
  alias LantternWeb.LearningContext.MomentFormComponent
  alias LantternWeb.Lessons.LessonsSideNavComponent

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_moment(params)
      |> assign_strand()
      |> assign(:description_form, nil)
      |> assign(:is_editing_moment, false)

    {:ok, socket}
  end

  defp assign_moment(socket, %{"id" => id}) do
    case LearningContext.get_moment(id) do
      moment when is_nil(moment) ->
        socket
        |> put_flash(:error, gettext("Couldn't find moment"))
        |> redirect(to: ~p"/strands")

      moment ->
        socket
        |> assign(:moment, moment)
    end
  end

  defp assign_strand(socket) do
    strand =
      LearningContext.get_strand(socket.assigns.moment.strand_id,
        preloads: [:subjects, :years]
      )

    socket
    |> assign(:strand, strand)
    |> assign(:page_title, "#{socket.assigns.moment.name} • #{strand.name}")
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, :params, params)}
  end

  # event handlers

  @impl true
  def handle_event("edit_moment", _params, socket),
    do: {:noreply, assign(socket, :is_editing_moment, true)}

  def handle_event("close_moment_form", _params, socket),
    do: {:noreply, assign(socket, :is_editing_moment, false)}

  # -- description

  def handle_event("edit_description", _params, socket) do
    form =
      socket.assigns.moment
      |> LearningContext.change_moment()
      |> to_form()

    {:noreply, assign(socket, :description_form, form)}
  end

  def handle_event("cancel_description_edit", _params, socket),
    do: {:noreply, assign(socket, :description_form, nil)}

  def handle_event("validate_description", %{"moment" => params}, socket) do
    form =
      socket.assigns.moment
      |> LearningContext.change_moment(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :description_form, form)}
  end

  def handle_event("save_description", %{"moment" => params}, socket) do
    case LearningContext.update_moment(socket.assigns.moment, params) do
      {:ok, moment} ->
        socket =
          socket
          |> assign(:moment, moment)
          |> assign(:description_form, nil)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :description_form, to_form(changeset))}
    end
  end

  # info handlers

  @impl true
  def handle_info({MomentFormComponent, {action, moment}}, socket)
      when action in [:created, :updated] do
    {:noreply, assign(socket, :moment, moment)}
  end
end
