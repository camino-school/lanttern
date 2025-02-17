defmodule LantternWeb.StudentsCycleInfo.StudentCycleProfilePictureOverlayComponent do
  @moduledoc """
  Renders student cycle profile picture overlay with form.

  ### Required attrs

  - `:student_cycle_info` - `%StudentCycleInfo{}`
  - `:student_name` - used to display in the profile picture field
  - `:current_profile_id` - in `socket.assigns.current_user.current_profile_id`, for logging
  - `:on_cancel` - `JS`, passed to `<.modal>`'s `on_cancel`

  """

  use LantternWeb, :live_component

  alias Lanttern.StudentsCycleInfo
  alias Lanttern.StudentsCycleInfo.StudentCycleInfo

  alias Lanttern.SupabaseHelpers
  import LantternWeb.FormHelpers, only: [consume_uploaded_profile_picture: 2]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id={@id} show on_cancel={@on_cancel}>
        <.form
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
          id={"#{@id}-form"}
        >
          <.profile_picture_field
            current_picture_url={@student_cycle_info.profile_picture_url}
            profile_name={@student_name}
            upload={@uploads.profile_picture}
            on_cancel={fn ref -> JS.push("cancel_upload", value: %{ref: ref}, target: @myself) end}
            on_save={fn -> JS.dispatch("submit", to: "##{@id}-form") end}
            on_remove={fn -> JS.push("remove_profile_picture", target: @myself) end}
          />
        </.form>
      </.modal>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> allow_upload(:profile_picture,
        accept: ~w(.jpg .jpeg .png .webp),
        max_file_size: 3_000_000,
        max_entries: 1
      )
      |> assign(:is_removing, false)
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
    |> assign_form()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_form(socket) do
    form =
      StudentsCycleInfo.change_student_cycle_info(socket.assigns.student_cycle_info)
      |> to_form()

    socket
    |> assign(:form, form)
  end

  # event handlers

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket),
    do: {:noreply, cancel_upload(socket, :profile_picture, ref)}

  # without this event, the image will not be displayed
  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("save", _params, socket) do
    profile_picture_url =
      consume_uploaded_profile_picture(socket, :profile_picture)

    socket =
      save_info(socket, %{profile_picture_url: profile_picture_url})
      |> case do
        {:ok, student_cycle_info} ->
          notify(__MODULE__, {:uploaded, student_cycle_info}, socket.assigns)

          # trigger remove object task to prevent keeping unused objects in bucket
          maybe_remove_object(socket.assigns.student_cycle_info)

          socket
          |> assign(:student_cycle_info, student_cycle_info)
          |> assign_form()

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event("remove_profile_picture", _params, socket) do
    socket =
      save_info(socket, %{profile_picture_url: nil})
      |> case do
        {:ok, student_cycle_info} ->
          notify(__MODULE__, {:removed, student_cycle_info}, socket.assigns)

          # trigger remove object task to prevent keeping unused objects in bucket
          maybe_remove_object(socket.assigns.student_cycle_info)

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

  defp maybe_remove_object(
         %{profile_picture_url: profile_picture_url} = _previous_student_cycle_info
       )
       when is_binary(profile_picture_url) do
    Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
      SupabaseHelpers.remove_object("profile_pictures", profile_picture_url)
    end)
  end

  defp maybe_remove_object(_previous_student_cycle_info), do: nil
end
