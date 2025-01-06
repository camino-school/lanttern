defmodule LantternWeb.StudentsCycleInfo.StudentCycleInfoFormComponent do
  @moduledoc """
  Renders notes markdown and editor.

  ### Required attrs

  - `:student_cycle_info` - `%StudentCycleInfo{}`
  - `:type` - "school" or "family"
  - `:current_profile_id` - in `socket.assigns.current_user.current_profile_id`

  ### Optional attrs

  - `:class`

  """

  use LantternWeb, :live_component

  alias Lanttern.StudentsCycleInfo
  alias Lanttern.StudentsCycleInfo.StudentCycleInfo

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} phx-submit="save" phx-target={@myself} id={@id}>
        <.textarea_with_actions
          id={@field.id}
          name={@field.name}
          value={@field.value}
          errors={@field.errors}
          label={@label}
          rows="10"
        >
          <:actions_left>
            <.markdown_supported />
          </:actions_left>
          <:actions>
            <.action type="button" theme="subtle" size="md" phx-click="cancel" phx-target={@myself}>
              <%= gettext("Cancel") %>
            </.action>
            <.action type="submit" theme="primary" size="md" icon_name="hero-check">
              <%= gettext("Save") %>
            </.action>
          </:actions>
        </.textarea_with_actions>
        <.error :for={{msg, _opts} <- @field.errors}><%= msg %></.error>
      </.form>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)

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
    |> assign(:class, nil)
    |> assign_form()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_form(socket) do
    form =
      StudentsCycleInfo.change_student_cycle_info(socket.assigns.student_cycle_info)
      |> to_form()

    field =
      case socket.assigns.type do
        "school" -> form[:school_info]
        "family" -> form[:family_info]
      end

    socket
    |> assign(:form, form)
    |> assign(:field, field)
  end

  # event handlers

  @impl true
  def handle_event("cancel", _params, socket) do
    notify(__MODULE__, {:cancel, socket.assigns.type}, socket.assigns)
    {:noreply, socket}
  end

  def handle_event("save", %{"student_cycle_info" => params}, socket) do
    socket =
      save_info(socket, params)
      |> case do
        {:ok, student_cycle_info} ->
          notify(__MODULE__, {:saved, student_cycle_info}, socket.assigns)

          socket
          |> assign(:student_cycle_info, student_cycle_info)
          |> assign_form()

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  # helpers

  defp save_info(socket, params) do
    %{
      assigns: %{
        student_cycle_info: %StudentCycleInfo{} = student_cycle_info,
        current_profile_id: current_profile_id
      }
    } = socket

    StudentsCycleInfo.update_student_cycle_info(
      student_cycle_info,
      params,
      log_profile_id: current_profile_id
    )
  end
end
