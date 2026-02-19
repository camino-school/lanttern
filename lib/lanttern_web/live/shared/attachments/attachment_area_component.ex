defmodule LantternWeb.Attachments.AttachmentAreaComponent do
  @moduledoc """
  Creates an attachment area UI.

  ### Supported contexts:

  - assessment point entry evidences (use `assessment_point_entry_id` assign)
  - student cycle info attachments (use `student_cycle_info_id` assign and `shared_with_student` assign)
  - lesson attachments (use `lesson_id` assign and `is_teacher_only_resource` assign)
  - ILP comments attachments (use `ilp_comment_id` assign)

  ### Supported attrs/assigns

  - `title` (optional, string)
  - `class` (optional, any)
  - `allow_editing` (optional, boolean)
  - `current_user` (optional, `%User{}`) - required when `allow_editing` is `true`
  - `assessment_point_entry_id` (optional, integer) - view supported contexts above
  - `student_cycle_info_id` (optional, integer) - view supported contexts above
  - `lesson_id` (optional, integer) - view supported contexts above
  - `shared_with_student` (optional, boolean) - used with student cycle info. View supported contexts above
  - `is_teacher_only_resource` (optional, boolean) - used with lesson. View supported contexts above

  """

  use LantternWeb, :live_component

  import Lanttern.Utils, only: [reorder: 3]

  alias Lanttern.Assessments
  alias Lanttern.Attachments
  alias Lanttern.Attachments.Attachment
  alias Lanttern.ILP
  alias Lanttern.Lessons
  alias Lanttern.StudentsCycleInfo
  alias Lanttern.SupabaseHelpers

  # shared

  import LantternWeb.AttachmentsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[@class, if(!@allow_editing && @attachments_length == 0, do: "hidden")]}>
      <div
        :if={@title}
        class={[
          "flex items-center gap-2",
          if(@shared_with_student, do: "text-ltrn-student-dark")
        ]}
      >
        <.icon name="hero-paper-clip" class="w-6 h-6" />
        <h5 class="font-display font-bold text-sm">{@title}</h5>
      </div>
      <.attachments_list
        :if={@attachments_length > 0}
        id={"#{@id}-attachments-list"}
        class={if @is_editing, do: "hidden"}
        attachments={@streams.attachments}
        allow_editing={@allow_editing}
        attachments_length={@attachments_length}
        sortable_group={@sortable_group}
        component_id={@id}
        on_toggle_share={nil}
        sortable_event="sort_attachments"
        on_edit={&JS.push("edit", value: %{"id" => &1}, target: @myself)}
        on_remove={&JS.push("delete", value: %{"id" => &1}, target: @myself)}
      />
      <div
        :if={@is_adding_external || @is_editing}
        class="p-4 border border-dashed border-ltrn-subtle rounded-sm mt-4 bg-white shadow-lg"
      >
        <.form
          for={@form}
          id="external-attachment-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.input
            field={@form[:name]}
            type="text"
            label={gettext("Attachment name")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.input
            field={@form[:link]}
            type="text"
            label={gettext("Link")}
            class="mb-6"
            phx-debounce="1500"
          />
          <div class="flex justify-end gap-2">
            <.button type="button" theme="ghost" phx-click="cancel" phx-target={@myself}>
              {gettext("Cancel")}
            </.button>
            <.button
              type="submit"
              phx-disable-with={gettext("Saving...")}
              id="save-external-attachment"
            >
              {gettext("Save")}
            </.button>
          </div>
        </.form>
      </div>
      <div
        :for={entry <- @uploads.attachment_file.entries}
        class="p-4 border border-dashed border-ltrn-subtle rounded-sm mt-4 shadow-lg bg-white"
      >
        <p class="flex items-center gap-2 text-sm text-ltrn-subtle">
          <.icon name="hero-paper-clip-mini" /> {gettext("File upload")}
        </p>
        <p class="mt-2 font-bold">
          {entry.client_name}
        </p>
        <.error_block :if={@invalid_upload_msg} class="mt-4">
          {@invalid_upload_msg}
        </.error_block>
        <div class="flex justify-end gap-4 mt-10">
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.push("cancel_upload", value: %{"ref" => entry.ref}, target: @myself)}
          >
            {gettext("Cancel")}
          </.button>
          <.button type="submit" form={"#{@id}-attachments-upload-form"} disabled={!entry.valid?}>
            {gettext("Upload")}
          </.button>
        </div>
      </div>
      <div
        :if={@allow_editing && !@is_adding_external && !@is_editing}
        class={
          [
            "grid grid-cols-2 gap-2 mt-4",
            # we don't use the conditional rendering with :if for attachment files
            # because we need the #attachments-upload-form for upload
            if(@uploads.attachment_file.entries != [], do: "hidden")
          ]
        }
      >
        <div
          class="p-4 border border-dashed border-ltrn-subtle rounded-sm text-center text-ltrn-subtle bg-white shadow-lg"
          phx-drop-target={@uploads.attachment_file.ref}
        >
          <form
            id={"#{@id}-attachments-upload-form"}
            phx-submit="upload"
            phx-change="validate_upload"
            phx-target={@myself}
          >
            <.icon name="hero-document-plus" class="h-8 w-8 mx-auto mb-6" />
            <div>
              <label
                for={@uploads.attachment_file.ref}
                class="cursor-pointer text-ltrn-primary hover:text-ltrn-dark focus-within:outline-hidden focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-ltrn-dark"
              >
                <span>{gettext("Upload a file")}</span>
                <.live_file_input upload={@uploads.attachment_file} class="sr-only" />
              </label>
              <span>{gettext("or drag and drop here")}</span>
            </div>
          </form>
        </div>
        <div class="p-4 border border-dashed border-ltrn-subtle rounded-sm text-center bg-white shadow-lg">
          <.icon name="hero-link" class="h-8 w-8 mx-auto mb-6 text-ltrn-subtle" />
          <div>
            <button
              type="button"
              class="inline text-ltrn-primary hover:text-ltrn-dark focus-within:outline-hidden focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-ltrn-dark"
              phx-click="add_external"
              phx-target={@myself}
              id={"#{@id}-external-link-button"}
            >
              {gettext("Or add a link to an external file")}
              <span class="text-ltrn-subtle">{gettext("(e.g. Google Docs)")}</span>
            </button>
          </div>
        </div>
      </div>
      <.error_block
        :if={@upload_error}
        class="mt-4"
        on_dismiss={JS.push("clear_upload_error", target: @myself)}
      >
        {@upload_error}
      </.error_block>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:title, nil)
      |> assign(:class, nil)
      |> assign(:allow_editing, false)
      |> assign(:attachment, nil)
      |> assign(:is_adding_external, false)
      |> assign(:is_editing, false)
      |> assign(:upload_error, nil)
      |> assign(:shared_with_student, nil)
      |> assign(:is_teacher_only_resource, nil)
      |> assign(:sortable_group, nil)
      |> allow_upload(:attachment_file,
        accept: :any,
        max_file_size: 5_000_000,
        max_entries: 1
      )
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(%{action: :receive_attachment} = assigns, socket) do
    %{attachment_id: attachment_id, new_index: new_index} = assigns

    socket =
      case socket.assigns.type do
        :lesson_attachments ->
          attachment = Attachments.get_attachment!(attachment_id)

          case Lessons.toggle_lesson_attachment_share(attachment) do
            {:ok, _updated_attachment} ->
              # Insert at dropped position in ids list
              attachments_ids =
                List.insert_at(socket.assigns.attachments_ids, new_index, attachment_id)

              # Update positions in DB
              Lessons.update_lesson_attachments_positions(attachments_ids)

              # OPTIMIZATION: Just update ids, don't reload all
              socket
              |> assign(:attachments_ids, attachments_ids)
              |> assign(:attachments_length, length(attachments_ids))

            {:error, _} ->
              put_flash(socket, :error, gettext("Failed to move attachment"))
          end

        _ ->
          put_flash(socket, :error, gettext("Operation not supported"))
      end

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
    |> assign_type()
    |> stream_attachments()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_type(%{assigns: %{assessment_point_entry_id: _}} = socket),
    do: assign(socket, :type, :entry_evidences)

  defp assign_type(%{assigns: %{student_cycle_info_id: _}} = socket),
    do: assign(socket, :type, :student_cycle_info_attachments)

  defp assign_type(%{assigns: %{lesson_id: _}} = socket),
    do: assign(socket, :type, :lesson_attachments)

  defp assign_type(%{assigns: %{ilp_comment_id: _}} = socket),
    do: assign(socket, :type, :ilp_comment_attachments)

  defp stream_attachments(
         %{assigns: %{type: :entry_evidences, assessment_point_entry_id: id}} = socket
       ) do
    attachments = Attachments.list_attachments(assessment_point_entry_id: id)
    handle_stream_attachments_socket_assigns(socket, attachments)
  end

  defp stream_attachments(
         %{assigns: %{type: :student_cycle_info_attachments, student_cycle_info_id: id}} = socket
       ) do
    attachments =
      Attachments.list_attachments(
        student_cycle_info_id: id,
        shared_with_student: {:student_cycle_info, socket.assigns.shared_with_student}
      )

    handle_stream_attachments_socket_assigns(socket, attachments)
  end

  defp stream_attachments(%{assigns: %{type: :lesson_attachments, lesson_id: id}} = socket) do
    attachments =
      Attachments.list_attachments(
        lesson_id: id,
        is_teacher_only_resource: {:lesson, socket.assigns.is_teacher_only_resource}
      )

    handle_stream_attachments_socket_assigns(socket, attachments)
  end

  defp stream_attachments(%{assigns: %{type: :ilp_comment_attachments}} = socket) do
    attachments = Attachments.list_attachments(ilp_comment_id: socket.assigns.ilp_comment_id)
    attachments_ids = Enum.map(attachments, & &1.id)

    socket
    |> stream(:attachments, attachments, reset: true)
    |> assign(:attachments_length, length(attachments))
    |> assign(:attachments_ids, attachments_ids)
  end

  defp handle_stream_attachments_socket_assigns(socket, attachments) do
    attachments_ids = Enum.map(attachments, & &1.id)

    socket
    |> stream(:attachments, attachments, reset: true)
    |> assign(:attachments_length, length(attachments))
    |> assign(:attachments_ids, attachments_ids)
  end

  # event handlers

  @impl true
  def handle_event("add_external", _, socket) do
    changeset =
      %Attachment{}
      |> Attachments.change_attachment()

    socket =
      socket
      |> assign(:is_adding_external, true)
      |> assign_form(changeset)

    {:noreply, socket}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    attachment = Attachments.get_attachment!(id)
    changeset = Attachments.change_attachment(attachment, %{})

    socket =
      socket
      |> assign(:is_editing, true)
      |> assign(:attachment, attachment)
      |> assign_form(changeset)

    {:noreply, socket}
  end

  def handle_event("cancel", _, socket) do
    socket =
      socket
      |> assign(:is_adding_external, false)
      |> assign(:is_editing, false)

    {:noreply, socket}
  end

  def handle_event("validate", %{"attachment" => attachment_params}, socket) do
    changeset =
      %Attachment{}
      |> Attachments.change_attachment(attachment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"attachment" => params}, socket) do
    case socket.assigns do
      %{is_adding_external: true} ->
        params =
          params
          |> Map.put("is_external", true)

        save_attachment(socket, :new, params)

      %{is_editing: true} ->
        save_attachment(socket, :edit, params)
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    attachment = Attachments.get_attachment!(id)

    case Attachments.delete_attachment(attachment) do
      {:ok, _attachment} ->
        notify(__MODULE__, {:deleted, attachment}, socket.assigns)

        socket =
          socket
          |> stream_attachments()

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> assign(:error_msg, gettext("Error deleting attachment"))

        {:noreply, socket}
    end
  end

  # Cross-component drag: from one AttachmentAreaComponent to another
  def handle_event(
        "sort_attachments",
        %{
          "from" => %{"componentId" => from_id},
          "to" => %{"componentId" => to_id},
          "oldIndex" => old_index,
          "newIndex" => new_index
        },
        socket
      )
      when from_id != to_id do
    # SOURCE component: remove and notify target

    {attachment_id, remaining_ids} =
      List.pop_at(socket.assigns.attachments_ids, old_index)

    # Validate attachment belongs to this component
    if attachment_id in socket.assigns.attachments_ids do
      send_update(__MODULE__,
        id: to_id,
        action: :receive_attachment,
        attachment_id: attachment_id,
        new_index: new_index
      )

      # Update our state (DON'T update positions in DB per user requirement)
      socket =
        socket
        |> assign(:attachments_ids, remaining_ids)
        |> assign(:attachments_length, length(remaining_ids))

      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, gettext("Invalid attachment"))}
    end
  end

  # Within-component drag: reordering within the same component
  def handle_event(
        "sort_attachments",
        %{"oldIndex" => old_index, "newIndex" => new_index} = _payload,
        socket
      )
      when old_index != new_index do
    attachments_ids =
      socket.assigns.attachments_ids
      |> reorder(old_index, new_index)

    case socket.assigns.type do
      :entry_evidences ->
        Assessments.update_assessment_point_entry_evidences_positions(attachments_ids)

      :student_cycle_info_attachments ->
        StudentsCycleInfo.update_student_cycle_info_attachments_positions(attachments_ids)

      :lesson_attachments ->
        Lessons.update_lesson_attachments_positions(attachments_ids)

      :ilp_comment_attachments ->
        ILP.update_ilp_comment_attachments_positions(attachments_ids)
    end
    |> case do
      :ok ->
        # OPTIMIZATION: Don't stream attachments (SortableJS already updated UI)
        # Just update the ids list in assigns
        {:noreply, assign(socket, :attachments_ids, attachments_ids)}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  # Catch-all for when indexes are the same (no movement)
  def handle_event("sort_attachments", _payload, socket), do: {:noreply, socket}

  def handle_event("validate_upload", _, socket) do
    upload_conf = socket.assigns.uploads.attachment_file

    invalid_upload_msg =
      case upload_conf.entries do
        [entry] -> upload_errors(upload_conf, entry)
        _ -> []
      end
      |> Enum.map(&upload_error_to_string(upload_conf, &1))
      |> case do
        [] -> nil
        error_messages -> Enum.join(error_messages, " ")
      end

    socket =
      socket
      |> assign(:invalid_upload_msg, invalid_upload_msg)

    {:noreply, socket}
  end

  def handle_event("upload", _, socket) do
    socket
    |> consume_uploaded_entries(:attachment_file, fn %{path: file_path}, entry ->
      opts = %{content_type: entry.client_type}

      case SupabaseHelpers.upload_object("attachments", entry.client_name, file_path, opts) do
        {:ok, object} ->
          attachment_path = URI.encode(object.key)
          {:ok, {:ok, {attachment_path, entry.client_name}}}

        {:error, %{message: message}} ->
          {:ok, {:error, message}}
      end
    end)
    |> hd()
    |> case do
      {:ok, {attachment_path, name}} ->
        save_attachment(socket, :new, %{"name" => name, "link" => attachment_path})

      {:error, message} ->
        {:noreply, assign(socket, :upload_error, message)}
    end
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment_file, ref)}
  end

  def handle_event("clear_upload_error", _, socket) do
    {:noreply, assign(socket, :upload_error, nil)}
  end

  # helpers

  # save attachment clauses:
  # :new -> when is_adding_external or uploading attachment
  # :edit -> when is_editing

  defp save_attachment(%{assigns: %{type: :entry_evidences}} = socket, :new, params) do
    %{
      current_user: current_user,
      assessment_point_entry_id: assessment_point_entry_id
    } = socket.assigns

    case Assessments.create_assessment_point_entry_evidence(
           current_user,
           assessment_point_entry_id,
           params
         ) do
      {:ok, attachment} ->
        notify(__MODULE__, {:created, attachment}, socket.assigns)

        socket =
          socket
          |> assign(:is_adding_external, false)
          |> stream_attachments()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_attachment(
         %{assigns: %{type: :student_cycle_info_attachments}} = socket,
         :new,
         params
       ) do
    %{
      current_user: current_user,
      student_cycle_info_id: student_cycle_info_id
    } = socket.assigns

    case StudentsCycleInfo.create_student_cycle_info_attachment(
           current_user.current_profile_id,
           student_cycle_info_id,
           params,
           socket.assigns.shared_with_student
         ) do
      {:ok, attachment} ->
        notify(__MODULE__, {:created, attachment}, socket.assigns)

        socket =
          socket
          |> assign(:is_adding_external, false)
          |> stream_attachments()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_attachment(%{assigns: %{type: :lesson_attachments}} = socket, :new, params) do
    %{
      current_user: current_user,
      lesson_id: lesson_id,
      is_teacher_only_resource: is_teacher_only_resource
    } = socket.assigns

    case Lessons.create_lesson_attachment(
           current_user.current_profile_id,
           lesson_id,
           params,
           is_teacher_only_resource || false
         ) do
      {:ok, attachment} ->
        notify(__MODULE__, {:created, attachment}, socket.assigns)

        socket =
          socket
          |> assign(:is_adding_external, false)
          |> stream_attachments()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_attachment(%{assigns: %{type: :ilp_comment_attachments}} = socket, :new, params) do
    %{
      current_profile: current_profile,
      ilp_comment_id: ilp_comment_id
    } = socket.assigns

    case ILP.create_ilp_comment_attachment(
           current_profile.id,
           ilp_comment_id,
           params
         ) do
      {:ok, attachment} ->
        socket =
          socket
          |> assign(:is_adding_external, false)
          |> stream_attachments()

        notify(__MODULE__, {:created, attachment}, socket.assigns)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_attachment(socket, :edit, params) do
    %{attachment: attachment} = socket.assigns

    case Attachments.update_attachment(attachment, params) do
      {:ok, attachment} ->
        notify(__MODULE__, {:edited, attachment}, socket.assigns)

        socket =
          socket
          |> assign(:is_editing, false)
          |> stream_attachments()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset),
    do: assign(socket, :form, to_form(changeset))
end
