defmodule LantternWeb.Schools.StudentFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Student` form

  ### Attrs

      attr :student, Student, required: true, doc: "requires virtual `email` loaded"
      attr :current_cycle, Cycle, doc: "used to separate current cycle from other classes"
      attr :current_user, required: true
      attr :current_scope, :any, required: true
      attr :title, :string, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :close_path, :string, required: true, doc: "Path to navigate to after successful save"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.Repo

  alias Lanttern.Identity
  alias Lanttern.Identity.Scope
  alias Lanttern.Identity.User
  alias Lanttern.Schools
  alias Lanttern.Schools.Student
  alias Lanttern.StudentTags

  # shared

  alias LantternWeb.Schools.ClassesFieldComponent
  alias LantternWeb.Schools.GuardiansSearchComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title>{@title}</:title>
        <.form
          id={"student-form-#{@id}"}
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            {gettext("Oops, something went wrong! Please check the errors below.")}
          </.error_block>
          <.input
            field={@form[:name]}
            type="text"
            label={gettext("Name")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.input
            field={@form[:birthdate]}
            type="date"
            label={gettext("Date of birth")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.live_component
            module={ClassesFieldComponent}
            id={"student-form-classes-picker-#{@id}"}
            class="mb-6"
            label={gettext("Classes")}
            school_id={@student.school_id}
            current_cycle={@current_cycle}
            selected_classes_ids={@selected_classes_ids}
            notify_component={@myself}
          />
          <div class="mb-6">
            <.label>{gettext("Student tags")}</.label>
            <%= if @student_tags != [] do %>
              <.badge_button_picker
                id={"student-tags-picker-#{@id}"}
                on_select={
                  &(JS.push("toggle_student_tag", value: %{"id" => &1}, target: @myself)
                    |> JS.dispatch("change", to: "#student-form-#{@id}"))
                }
                items={@student_tags}
                selected_ids={@selected_student_tags_ids}
                use_color_map_as_active
              />
            <% else %>
              <.empty_state_simple>{gettext("No selected classes")}</.empty_state_simple>
            <% end %>
          </div>
          <div class="mb-6">
            <.live_component
              module={GuardiansSearchComponent}
              id="guardians-search"
              notify_component={@myself}
              label={gettext("Guardians")}
              refocus_on_select="true"
              current_scope={@current_scope}
            />
            <%= if @guardians != [] do %>
              <ol class="mt-4 text-sm leading-relaxed list-decimal list-inside">
                <li :for={guardian <- @guardians} id={"selected-guardian-#{guardian.id}"}>
                  {guardian.name}
                  <.button
                    type="button"
                    icon_name="hero-x-mark-mini"
                    class="align-middle"
                    size="sm"
                    theme="ghost"
                    rounded
                    phx-click={
                      JS.push("remove_guardian", value: %{"id" => guardian.id}, target: @myself)
                    }
                  />
                </li>
              </ol>
            <% else %>
              <.empty_state_simple class="mt-4">
                {gettext("No guardians added to this student")}
              </.empty_state_simple>
            <% end %>
          </div>
          <.card_base class="p-6">
            <h3 class="font-display font-bold text-xl text-ltrn-dark">
              {gettext("User emails")}
            </h3>
            <p class="font-serif text-base text-ltrn-primary mt-1">
              {gettext("User emails allow students and guardians to log in to Lanttern.")}
            </p>
            <.input
              field={@form[:email]}
              type="email"
              label={gettext("Student")}
              placeholder={gettext("student@example.com")}
              class="mt-6"
              phx-debounce="1500"
            />
            <div :if={Scope.has_permission?(@current_scope, "school_management")} class="mt-6">
              <.label>{gettext("Guardians")}</.label>
              <div
                :for={{email, index} <- Enum.with_index(@guardian_user_emails)}
                class="flex items-center gap-2 mt-2"
              >
                <.input
                  id={"guardian-email-#{index}"}
                  name={"guardian_emails[#{index}]"}
                  type="email"
                  value={email}
                  placeholder={gettext("guardian@example.com")}
                  label=""
                  class="flex-1"
                  phx-debounce="1500"
                />
                <.button
                  type="button"
                  icon_name="hero-x-mark-mini"
                  sr_text={gettext("Remove")}
                  theme="ghost"
                  size="sm"
                  rounded
                  phx-click={
                    JS.push("remove_guardian_email", value: %{"index" => index}, target: @myself)
                  }
                />
              </div>
              <div class="flex justify-center mt-3">
                <.button
                  type="button"
                  size="sm"
                  phx-click={JS.push("add_guardian_email", target: @myself)}
                >
                  {gettext("Add another guardian user")}
                </.button>
              </div>
              <.error_block :if={@guardian_emails_error} class="mt-4">
                {@guardian_emails_error}
              </.error_block>
            </div>
          </.card_base>
        </.form>
        <:actions_left :if={@student.id}>
          <.button
            :if={is_nil(@student.deactivated_at)}
            type="button"
            theme="ghost"
            phx-click="deactivate"
            phx-target={@myself}
            data-confirm={gettext("Are you sure? You can reactive the student later.")}
          >
            {gettext("Deactivate")}
          </.button>
          <.button
            :if={@student.deactivated_at}
            type="button"
            theme="ghost"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
          </.button>
          <.button
            :if={@student.deactivated_at}
            type="button"
            theme="ghost"
            phx-click="reactivate"
            phx-target={@myself}
          >
            {gettext("Reactivate")}
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "##{@id}")}
          >
            {gettext("Cancel")}
          </.button>
          <.button
            type="submit"
            form={"student-form-#{@id}"}
          >
            {gettext("Save")}
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket = assign(socket, :initialized, false)
    {:ok, socket}
  end

  @impl true
  def update(
        %{action: {ClassesFieldComponent, {:changed, selected_classes_ids}}},
        socket
      ),
      do: {:ok, assign(socket, :selected_classes_ids, selected_classes_ids)}

  def update(
        %{action: {GuardiansSearchComponent, {:selected, guardian}}},
        socket
      ) do
    guardians =
      [guardian | socket.assigns.guardians]
      |> Enum.uniq()
      |> Enum.sort_by(& &1.name)

    selected_guardians_ids = Enum.map(guardians, & &1.id)

    {:ok, assign(socket, guardians: guardians, selected_guardians_ids: selected_guardians_ids)}
  end

  def update(%{student: %Student{}} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_form()
    |> assign_student_tags()
    |> assign_guardians()
    |> assign_guardian_user_emails()
    |> assign(:guardian_emails_error, nil)
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_form(socket) do
    student =
      socket.assigns.student
      |> ensure_classes_preload()
      |> ensure_tags_preload()
      |> ensure_student_tag_relationships_preload()
      |> ensure_guardians_preload()

    changeset = Schools.change_student(student)

    selected_classes_ids = Enum.map(student.classes, & &1.id)
    selected_student_tags_ids = Enum.map(student.tags, & &1.id)
    selected_guardians_ids = Enum.map(student.guardians, & &1.id)

    socket
    |> assign(:student, student)
    |> assign(:form, to_form(changeset))
    |> assign(:selected_classes_ids, selected_classes_ids)
    |> assign(:selected_student_tags_ids, selected_student_tags_ids)
    |> assign(:selected_guardians_ids, selected_guardians_ids)
  end

  defp ensure_classes_preload(%Student{classes: classes} = student) when not is_list(classes) do
    Repo.preload(student, [:classes])
  end

  defp ensure_classes_preload(student), do: student

  defp ensure_tags_preload(%Student{tags: tags} = student) when not is_list(tags) do
    Repo.preload(student, [:tags])
  end

  defp ensure_tags_preload(student), do: student

  defp ensure_student_tag_relationships_preload(
         %Student{student_tag_relationships: student_tag_relationships} = student
       )
       when not is_list(student_tag_relationships) do
    Repo.preload(student, [:student_tag_relationships])
  end

  defp ensure_student_tag_relationships_preload(student), do: student

  defp ensure_guardians_preload(%Student{guardians: guardians} = student)
       when not is_list(guardians) do
    Repo.preload(student, [:guardians])
  end

  defp ensure_guardians_preload(student), do: student

  defp assign_student_tags(socket) do
    student_tags = StudentTags.list_student_tags(school_id: socket.assigns.student.school_id)

    socket
    |> assign(:student_tags, student_tags)
  end

  defp assign_guardians(socket) do
    # Load guardians that are currently associated with the student
    guardians =
      case socket.assigns.student.guardians do
        guardians when is_list(guardians) ->
          guardians

        _ ->
          socket.assigns.student
          |> Repo.preload(:guardians)
          |> Map.get(:guardians, [])
      end

    socket
    |> assign(:guardians, guardians)
  end

  defp assign_guardian_user_emails(socket) do
    %{student: student, current_scope: scope} = socket.assigns

    emails =
      if student.id && Scope.has_permission?(scope, "school_management") do
        Identity.list_student_guardian_user_emails(scope, student)
      else
        []
      end

    assign(socket, :guardian_user_emails, ensure_at_least_one_email(emails))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"student" => student_params} = params, socket) do
    guardian_emails = extract_guardian_emails(params)

    socket =
      socket
      |> assign(:guardian_user_emails, guardian_emails)
      |> assign(:guardian_emails_error, nil)
      |> assign_validated_form(student_params)

    {:noreply, socket}
  end

  def handle_event("toggle_student_tag", %{"id" => tag_id}, socket) do
    selected_student_tags_ids =
      if tag_id in socket.assigns.selected_student_tags_ids,
        do: Enum.filter(socket.assigns.selected_student_tags_ids, fn id -> id != tag_id end),
        else: [tag_id | socket.assigns.selected_student_tags_ids]

    {:noreply, assign(socket, :selected_student_tags_ids, selected_student_tags_ids)}
  end

  def handle_event("remove_guardian", %{"id" => id}, socket) do
    guardians =
      socket.assigns.guardians
      |> Enum.reject(&(&1.id == id))

    selected_guardians_ids = Enum.map(guardians, & &1.id)

    {:noreply,
     assign(socket, guardians: guardians, selected_guardians_ids: selected_guardians_ids)}
  end

  def handle_event("add_guardian_email", _params, socket) do
    emails = socket.assigns.guardian_user_emails ++ [""]
    {:noreply, assign(socket, :guardian_user_emails, emails)}
  end

  def handle_event("remove_guardian_email", %{"index" => index}, socket) do
    # index arrives as integer from JS.push JSON serialization
    emails =
      socket.assigns.guardian_user_emails
      |> List.delete_at(index)

    {:noreply, assign(socket, :guardian_user_emails, ensure_at_least_one_email(emails))}
  end

  def handle_event("save", %{"student" => student_params} = params, socket) do
    student_params = inject_extra_params(socket, student_params)
    guardian_emails = extract_guardian_emails(params)

    invalid_emails =
      guardian_emails
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 != ""))
      |> Enum.reject(&User.valid_email?/1)

    if invalid_emails != [] do
      {:noreply,
       assign(
         socket,
         :guardian_emails_error,
         gettext("Some guardian emails are invalid. Please check and try again.")
       )}
    else
      save_student(socket, socket.assigns.student.id, student_params, guardian_emails)
    end
  end

  def handle_event("deactivate", _, socket) do
    Schools.deactivate_student(socket.assigns.student)
    |> case do
      {:ok, student} ->
        notify(__MODULE__, {:deactivated, student}, socket.assigns)
        {:noreply, push_patch(socket, to: socket.assigns.close_path)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("delete", _, socket) do
    Schools.delete_student(socket.assigns.student)
    |> case do
      {:ok, student} ->
        notify(__MODULE__, {:deleted, student}, socket.assigns)
        {:noreply, push_patch(socket, to: socket.assigns.close_path)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("reactivate", _, socket) do
    Schools.reactivate_student(socket.assigns.student)
    |> case do
      {:ok, student} ->
        notify(__MODULE__, {:reactivated, student}, socket.assigns)
        {:noreply, push_patch(socket, to: socket.assigns.close_path)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.student
      |> Schools.change_student(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.student.school_id)
    |> Map.put("classes_ids", socket.assigns.selected_classes_ids)
    |> Map.put("tags_ids", socket.assigns.selected_student_tags_ids)
    |> Map.put("guardians_ids", socket.assigns.selected_guardians_ids)
  end

  defp save_student(socket, nil, student_params, guardian_emails) do
    result =
      Schools.save_student_with_guardian_accounts(
        socket.assigns.current_scope,
        nil,
        student_params,
        guardian_changes(socket),
        guardian_emails
      )

    handle_save_result(result, :created, socket)
  end

  defp save_student(socket, _id, student_params, guardian_emails) do
    result =
      Schools.save_student_with_guardian_accounts(
        socket.assigns.current_scope,
        socket.assigns.student,
        student_params,
        guardian_changes(socket),
        guardian_emails
      )

    handle_save_result(result, :updated, socket)
  end

  defp handle_save_result(result, action, socket) do
    case result do
      {:ok, student} ->
        notify(__MODULE__, {action, student}, socket.assigns)
        {:noreply, push_patch(socket, to: socket.assigns.close_path)}

      {:error, {:student, %Ecto.Changeset{} = changeset}} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, :guardian_accounts} ->
        socket =
          assign(
            socket,
            :guardian_emails_error,
            gettext("Could not save guardian accounts. Please check the emails and try again.")
          )

        {:noreply, socket}
    end
  end

  defp ensure_at_least_one_email([]), do: [""]
  defp ensure_at_least_one_email(emails), do: emails

  defp extract_guardian_emails(params) do
    case Map.get(params, "guardian_emails") do
      map when is_map(map) ->
        map
        |> Enum.reject(fn {k, _v} -> String.starts_with?(k, "_") end)
        |> Enum.sort_by(fn {k, _v} -> String.to_integer(k) end)
        |> Enum.map(fn {_k, v} -> v end)

      _ ->
        [""]
    end
  end

  defp guardian_changes(socket) do
    selected_ids = socket.assigns.selected_guardians_ids
    current_ids = Enum.map(socket.assigns.student.guardians, & &1.id)
    scope = socket.assigns.current_scope

    guardians_to_add =
      (selected_ids -- current_ids)
      |> Enum.map(&Schools.get_guardian!(scope, &1))

    guardian_ids_to_remove = current_ids -- selected_ids

    {guardians_to_add, guardian_ids_to_remove}
  end
end
