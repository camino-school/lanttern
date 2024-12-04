defmodule LantternWeb.StrandLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  # page components
  alias __MODULE__.AboutComponent
  alias __MODULE__.StrandRubricsComponent
  alias __MODULE__.AssessmentComponent
  alias __MODULE__.MomentsComponent
  alias __MODULE__.NotesComponent

  # shared components
  alias LantternWeb.LearningContext.StrandFormComponent

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_strand(params)

    {:ok, socket}
  end

  defp assign_strand(socket, %{"id" => id}) do
    case LearningContext.get_strand(id, preloads: [:subjects, :years]) do
      strand when is_nil(strand) ->
        socket
        |> put_flash(:error, gettext("Couldn't find strand"))
        |> redirect(to: ~p"/strands")

      strand ->
        socket
        |> assign(:strand, strand)
        |> assign(:page_title, strand.name)
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign_is_editing(params)

    {:noreply, socket}
  end

  defp assign_is_editing(socket, %{"is_editing" => "true"}),
    do: assign(socket, :is_editing, true)

  defp assign_is_editing(socket, _params),
    do: assign(socket, :is_editing, false)

  # event handlers

  @impl true
  def handle_event("delete_strand", _params, socket) do
    case LearningContext.delete_strand(socket.assigns.strand) do
      {:ok, _strand} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Strand deleted"))
         |> push_navigate(to: ~p"/strands")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           gettext(
             "Strand has linked moments and/or assessment points (goals). Deleting it would cause some data loss."
           )
         )}
    end
  end

  # info handlers

  @impl true
  def handle_info({StrandFormComponent, {:saved, strand}}, socket) do
    {:noreply, assign(socket, :strand, strand)}
  end
end
