defmodule LantternWeb.Schools.StaffMemberFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `StaffMember` form

  ### Attrs

      attr :staff_member, Staff, required: true, doc: "requires email field loaded"
      attr :title, :string, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.Schools

  import LantternWeb.FormHelpers, only: [consume_uploaded_profile_picture: 2]

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.form
          id="staff-member-form"
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors below.") %>
          </.error_block>
          <.profile_picture_field
            current_picture_url={@staff_member.profile_picture_url}
            upload={@uploads.profile_picture}
            is_removing={@is_removing_profile_picture}
            on_cancel={
              fn ref ->
                JS.push("cancel_profile_picture_upload", value: %{ref: ref}, target: @myself)
              end
            }
            on_remove={fn -> JS.push("remove_profile_picture", target: @myself) end}
            on_cancel_remove={fn -> JS.push("cancel_remove_profile_picture", target: @myself) end}
            class="mb-6"
          />
          <.input
            field={@form[:name]}
            type="text"
            label={gettext("Name")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.input
            field={@form[:role]}
            type="text"
            label={gettext("Role")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.card_base class="p-4" bg_class="bg-ltrn-mesh-cyan">
            <.input
              field={@form[:email]}
              type="email"
              label={gettext("Lanttern user email")}
              phx-debounce="1500"
            />
            <p class="flex items-center gap-2 mt-4">
              <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
              <%= gettext("Enables the user to login at Lanttern via Google Sign In") %>
            </p>
          </.card_base>
        </.form>
        <:actions_left :if={@staff_member.id}>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click="deactivate"
            phx-target={@myself}
            data-confirm={gettext("Are you sure? You can reactive the staff member later.")}
          >
            <%= gettext("Deactivate") %>
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
            form="staff-member-form"
          >
            <%= gettext("Save") %>
          </.action>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:is_removing_profile_picture, false)
      |> assign(:initialized, false)
      |> allow_upload(:profile_picture,
        accept: ~w(.jpg .jpeg .png .webp),
        max_file_size: 3_000_000,
        max_entries: 1
      )

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
    staff_member = socket.assigns.staff_member
    changeset = Schools.change_staff_member(staff_member)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("cancel_profile_picture_upload", %{"ref" => ref}, socket),
    do: {:noreply, cancel_upload(socket, :profile_picture, ref)}

  def handle_event("remove_profile_picture", _, socket),
    do: {:noreply, assign(socket, :is_removing_profile_picture, true)}

  def handle_event("cancel_remove_profile_picture", _, socket),
    do: {:noreply, assign(socket, :is_removing_profile_picture, false)}

  def handle_event("validate", %{"staff_member" => staff_member_params}, socket),
    do: {:noreply, assign_validated_form(socket, staff_member_params)}

  def handle_event("save", %{"staff_member" => staff_member_params}, socket) do
    profile_picture_url =
      consume_uploaded_profile_picture(socket, :profile_picture)

    # besides "consumed" profile picture, we should also consider is_removing_profile_picture flag
    profile_picture_url =
      cond do
        profile_picture_url -> profile_picture_url
        socket.assigns.is_removing_profile_picture -> nil
        true -> socket.assigns.staff_member.profile_picture_url
      end

    staff_member_params =
      inject_extra_params(socket, staff_member_params)
      |> Map.put("profile_picture_url", profile_picture_url)

    save_staff_member(socket, socket.assigns.staff_member.id, staff_member_params)
  end

  def handle_event("deactivate", _, socket) do
    Schools.deactivate_staff_member(socket.assigns.staff_member)
    |> case do
      {:ok, staff_member} ->
        notify(__MODULE__, {:deactivated, staff_member}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.staff_member
      |> Schools.change_staff_member(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.staff_member.school_id)
  end

  defp save_staff_member(socket, nil, staff_member_params) do
    Schools.create_staff_member(staff_member_params)
    |> case do
      {:ok, staff_member} ->
        notify(__MODULE__, {:created, staff_member}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_staff_member(socket, _id, staff_member_params) do
    Schools.update_staff_member(
      socket.assigns.staff_member,
      staff_member_params
    )
    |> case do
      {:ok, staff_member} ->
        notify(__MODULE__, {:updated, staff_member}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
