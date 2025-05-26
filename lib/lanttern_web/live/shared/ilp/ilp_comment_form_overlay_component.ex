defmodule LantternWeb.ILP.ILPCommentFormOverlayComponent do
  @moduledoc """
   to-do
  """

  use LantternWeb, :live_component

  alias Lanttern.ILP
  # alias Lanttern.ILP.ILPEntry

  alias Lanttern.ILP.ILPComment

  # shared components
  # import LantternWeb.ILPComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= gettext("New Comment") %></:title>
        <.form
          id="student-ilp-comment-form"
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors below.") %>
          </.error_block>
          <.input
            field={@form[:name]}
            type="text"
            label={gettext("Title")}
            class="mb-1"
            phx-debounce="1500"
          />
          <.input
            field={@form[:content]}
            type="textarea"
            label={gettext("Content")}
            class="mb-1"
            phx-debounce="1500"
          />
          <.markdown_supported />
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors above.") %>
          </.error_block>
        </.form>

        <:actions_left :if={@comment.id}>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.action>
        </:actions_left>
        <:actions>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click={JS.exec("data-cancel", to: "##{@id}")}
          >
            <%= gettext("Cancel") %>
          </.action>
          <.action
            type="submit"
            theme="primary"
            size="md"
            icon_name="hero-check"
            form="student-ilp-comment-form"
          >
            <%= gettext("Save") %>
          </.action>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  # function components

  # attr :entry, ILPEntry
  # attr :class, :any, default: nil

  # defp ilp_entry(%{entry: %{description: nil}} = assigns) do
  #   ~H"""
  #   <.empty_state_simple class={@class}>
  #     <%= gettext("Nothing yet") %>
  #   </.empty_state_simple>
  #   """
  # end

  # defp ilp_entry(assigns) do
  #   ~H"""
  #   <.markdown text={@entry.description} class={["max-w-none", @class]} />
  #   """
  # end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:show_actions, false)
      |> assign(:on_edit_patch, nil)
      |> assign(:create_patch, nil)
      |> assign(:class, nil)
      |> assign(:show_teacher_notes, false)
      |> assign(:is_ilp_manager, false)
      |> assign(:initialized, false)
      |> assign(:comment, %ILPComment{})

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_form()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_form(socket) do
    changeset = ILP.change_ilp_comment(%ILPComment{})

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"ilp_comment" => comment_params}, socket) do
    changeset =
      ILPComment.changeset(socket.assigns.comment, comment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"ilp_comment" => comment_params}, socket) do
    save_ilp_comment(socket, :save, comment_params)
  end

  def handle_event("toggle_shared", params, socket) do
    ILP.update_student_ilp_sharing(
      socket.assigns.student_ilp,
      params,
      log_profile_id: socket.assigns.current_profile.id
    )
    |> case do
      {:ok, student_ilp} ->
        student_ilp = %{
          socket.assigns.student_ilp
          | is_shared_with_student: student_ilp.is_shared_with_student,
            is_shared_with_guardians: student_ilp.is_shared_with_guardians
        }

        socket =
          socket
          |> assign(:student_ilp, student_ilp)

        {:noreply, socket}

      {:error, _changeset} ->
        # handle error
        {:noreply, socket}
    end
  end

  defp save_ilp_comment(socket, :save, params) do
    params =
      params
      |> Map.put("position", 0)
      |> Map.put("shared_with_students", false)
      |> Map.put("student_ilp_id", socket.assigns.student_ilp.id)
      |> Map.put("owner_id", socket.assigns.current_profile.id)

    case ILP.create_ilp_comment(params) do
      {:ok, comment} ->
        notify(__MODULE__, {:created, comment}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
