defmodule LantternWeb.ILP.ILPCommentFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `StudentILPComment` form

  ### Attrs
      attr :ilp_comment, ILPComment, required: true
      attr :id, :string, required: true
      attr :form_action, :string, required: true
      attr :student_ilp, StudentILP, required: true
      attr :title, :string, required: true
      attr :current_profile, Profile, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID
  """

  use LantternWeb, :live_component

  alias Lanttern.ILP

  alias Lanttern.ILP.ILPComment
  alias LantternWeb.Attachments.AttachmentAreaComponent

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:show_actions, false)
      |> assign(:on_edit_patch, nil)
      |> assign(:create_patch, nil)
      |> assign(:class, nil)
      |> assign(:is_ilp_manager, false)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.form
          id="ilp-comment-form"
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors below.") %>
          </.error_block>
          <.input
            field={@form[:content]}
            type="markdown"
            label={gettext("Content")}
            phx-debounce="1500"
          />
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors above.") %>
          </.error_block>
        </.form>
        <.live_component
          :if={@form_action == :edit}
          ilp_comment_id={@ilp_comment.id}
          module={AttachmentAreaComponent}
          id="ilp-comment"
          title={gettext("Attachments")}
          allow_editing={true}
          notify_parent
          class="mt-10"
          current_profile={@current_profile}
          ilp_comment={@ilp_comment}
        />
        <:actions_left :if={@ilp_comment.id}>
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
            form="ilp-comment-form"
            id="save-action-ilp-comment"
          >
            <%= gettext("Save") %>
          </.action>
        </:actions>
      </.slide_over>
    </div>
    """
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
    changeset = ILP.change_ilp_comment(socket.assigns.ilp_comment)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"ilp_comment" => comment_params}, socket) do
    changeset =
      ILPComment.changeset(socket.assigns.ilp_comment, comment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"ilp_comment" => comment_params}, socket),
    do: save_ilp_comment(socket, socket.assigns.form_action, comment_params)

  def handle_event("delete", _, socket) do
    case ILP.delete_ilp_comment(socket.assigns.ilp_comment,
           log_profile_id: socket.assigns.current_profile.id
         ) do
      {:ok, ilp_comment} ->
        notify(__MODULE__, {:deleted, ilp_comment}, socket.assigns)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_ilp_comment(socket, :new, params) do
    params =
      params
      |> Map.put("position", 0)
      |> Map.put("student_ilp_id", socket.assigns.student_ilp.id)
      |> Map.put("owner_id", socket.assigns.current_profile.id)

    case ILP.create_ilp_comment(params, log_profile_id: socket.assigns.current_profile.id) do
      {:ok, comment} ->
        notify(__MODULE__, {:created, comment}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_ilp_comment(socket, :edit, params) do
    profile_id = socket.assigns.current_profile.id

    case ILP.update_ilp_comment(socket.assigns.ilp_comment, params, log_profile_id: profile_id) do
      {:ok, comment} ->
        notify(__MODULE__, {:updated, comment}, socket.assigns)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
