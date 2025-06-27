defmodule LantternWeb.Attachments.AttachmentAreaComponent do
  @moduledoc """
  Creates an attachment area UI.

  ### Supported contexts:

  - notes attachments (use `note_id` assign)
  - assessment point entry evidences (use `assessment_point_entry_id` assign)
  - student cycle info attachments (use `student_cycle_info_id` assign and `shared_with_student` assign)
  - moment card attachments (use `moment_card_id` assign and `shared_with_student` assign)
  - ILP comments attachments (use `ilp_comment_id` assign)

  ### Supported attrs/assigns

  - `title` (optional, string)
  - `class` (optional, any)
  - `allow_editing` (optional, boolean)
  - `current_user` (optional, `%User{}`) - required when `allow_editing` is `true`
  - `note_id` (optional, integer) - view supported contexts above
  - `assessment_point_entry_id` (optional, integer) - view supported contexts above
  - `student_cycle_info_id` (optional, integer) - view supported contexts above
  - `moment_card_id` (optional, integer) - view supported contexts above
  - `shared_with_student` (optional, boolean) - used with student cycle info and moment card. View supported contexts above

  """

  alias Lanttern.Assessments
  use LantternWeb, :live_component

  import Lanttern.Utils, only: [swap: 3]
  alias Lanttern.SupabaseHelpers

  alias Lanttern.Attachments
  alias Lanttern.Attachments.Attachment
  alias Lanttern.ILP
  alias Lanttern.ILP.ILPCommentAttachment
  alias Lanttern.LearningContext
  alias Lanttern.Notes
  alias Lanttern.StudentsCycleInfo

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
        <h5 class="font-display font-bold text-sm"><%= @title %></h5>
      </div>
      <.attachments_list
        :if={@attachments_length > 0}
        id={"#{@id}-attachments-list"}
        class={if @is_editing, do: "hidden"}
        attachments={@streams.attachments}
        allow_editing={@allow_editing}
        attachments_length={@attachments_length}
        on_toggle_share={
          if @allow_editing && @type == :moment_card_attachments,
            do: fn attachment_id, i ->
              JS.push("toggle_moment_card_attachment_share",
                value: %{"attachment_id" => attachment_id, "index" => i},
                target: @myself
              )
            end
        }
        on_move_up={
          fn i ->
            JS.push("reorder_attachments",
              value: %{from: i, to: i - 1},
              target: @myself
            )
          end
        }
        on_move_down={
          fn i ->
            JS.push("reorder_attachments",
              value: %{from: i, to: i + 1},
              target: @myself
            )
          end
        }
        on_edit={
          fn id ->
            JS.push("edit", value: %{"id" => id}, target: @myself)
          end
        }
        on_remove={
          fn id ->
            JS.push("delete", value: %{"id" => id}, target: @myself)
          end
        }
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
              <%= gettext("Cancel") %>
            </.button>
            <.button
              type="submit"
              phx-disable-with={gettext("Saving...")}
              id="save-external-attachment"
            >
              <%= gettext("Save") %>
            </.button>
          </div>
        </.form>
      </div>
      <div
        :for={entry <- @uploads.attachment_file.entries}
        class="p-4 border border-dashed border-ltrn-subtle rounded-sm mt-4 shadow-lg bg-white"
      >
        <p class="flex items-center gap-2 text-sm text-ltrn-subtle">
          <.icon name="hero-paper-clip-mini" />
          <%= gettext("File upload") %>
        </p>
        <p class="mt-2 font-bold">
          <%= entry.client_name %>
        </p>
        <.error_block :if={@invalid_upload_msg} class="mt-4">
          <%= @invalid_upload_msg %>
        </.error_block>
        <div class="flex justify-end gap-4 mt-10">
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.push("cancel_upload", value: %{"ref" => entry.ref}, target: @myself)}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form={"#{@id}-attachments-upload-form"} disabled={!entry.valid?}>
            <%= gettext("Upload") %>
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
                <span><%= gettext("Upload a file") %></span>
                <.live_file_input upload={@uploads.attachment_file} class="sr-only" />
              </label>
              <span><%= gettext("or drag and drop here") %></span>
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
              id="external-link-button"
            >
              <%= gettext("Or add a link to an external file") %>
              <span class="text-ltrn-subtle"><%= gettext("(e.g. Google Docs)") %></span>
            </button>
          </div>
        </div>
      </div>
      <.error_block
        :if={@upload_error}
        class="mt-4"
        on_dismiss={JS.push("clear_upload_error", target: @myself)}
      >
        <%= @upload_error %>
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
      |> stream_configure(
        :attachments,
        dom_id: fn {attachment, _i} -> "attachment-#{attachment.id}" end
      )
      |> allow_upload(:attachment_file,
        accept: :any,
        max_file_size: 5_000_000,
        max_entries: 1
      )
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
    |> assign_type()
    |> stream_attachments()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_type(%{assigns: %{note_id: _}} = socket),
    do: assign(socket, :type, :note_attachments)

  defp assign_type(%{assigns: %{assessment_point_entry_id: _}} = socket),
    do: assign(socket, :type, :entry_evidences)

  defp assign_type(%{assigns: %{student_cycle_info_id: _}} = socket),
    do: assign(socket, :type, :student_cycle_info_attachments)

  defp assign_type(%{assigns: %{moment_card_id: _}} = socket),
    do: assign(socket, :type, :moment_card_attachments)

  defp assign_type(%{assigns: %{ilp_comment_id: _}} = socket),
    do: assign(socket, :type, :ilp_comments_attachments)

  defp stream_attachments(%{assigns: %{type: :note_attachments, note_id: id}} = socket) do
    attachments = Attachments.list_attachments(note_id: id)
    handle_stream_attachments_socket_assigns(socket, attachments)
  end

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

  defp stream_attachments(
         %{assigns: %{type: :moment_card_attachments, moment_card_id: id}} = socket
       ) do
    attachments =
      Attachments.list_attachments(
        moment_card_id: id,
        shared_with_student: {:moment_card, socket.assigns.shared_with_student}
      )

    handle_stream_attachments_socket_assigns(socket, attachments)
  end

  defp stream_attachments(%{assigns: %{type: :ilp_comments_attachments}} = socket) do
    attachments = ILP.list_ilp_comment_attachments(socket.assigns.ilp_comment_id)
    attachments_ids = Enum.map(attachments, & &1.id)

    socket
    |> stream(:attachments, Enum.with_index(attachments), reset: true)
    |> assign(:attachments_length, length(attachments))
    |> assign(:attachments_ids, attachments_ids)
  end

  defp handle_stream_attachments_socket_assigns(socket, attachments) do
    attachments_ids = Enum.map(attachments, & &1.id)

    socket
    |> stream(:attachments, Enum.with_index(attachments), reset: true)
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

  def handle_event("edit", params, %{assigns: %{type: :ilp_comments_attachments}} = socket) do
    attachment = ILP.get_ilp_comment_attachment!(params["id"])
    changeset = ILP.change_ilp_comment_attachment(attachment, %{})

    socket =
      socket
      |> assign(:is_editing, true)
      |> assign(:attachment, attachment)
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

  def handle_event("validate", %{"ilp_comment_attachment" => params}, socket) do
    changeset =
      %ILPCommentAttachment{}
      |> ILPCommentAttachment.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
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

  def handle_event("save", %{"ilp_comment_attachment" => params}, socket) do
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

  def handle_event("delete", params, %{assigns: %{type: :ilp_comments_attachments}} = socket) do
    attachment = ILP.get_ilp_comment_attachment!(params["id"])

    case ILP.delete_ilp_comment_attachment(attachment) do
      {:ok, _attachment} ->
        socket =
          socket
          |> stream_attachments()

        notify(__MODULE__, {:deleted, attachment}, socket.assigns)

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> assign(:error_msg, gettext("Error deleting attachment"))

        {:noreply, socket}
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

  def handle_event("reorder_attachments", %{"from" => i, "to" => j}, socket) do
    attachments_ids =
      socket.assigns.attachments_ids
      |> swap(i, j)

    case socket.assigns.type do
      :note_attachments ->
        Notes.update_note_attachments_positions(attachments_ids)

      :entry_evidences ->
        Assessments.update_assessment_point_entry_evidences_positions(attachments_ids)

      :student_cycle_info_attachments ->
        StudentsCycleInfo.update_student_cycle_info_attachments_positions(attachments_ids)

      :moment_card_attachments ->
        LearningContext.update_moment_card_attachments_positions(attachments_ids)

      :ilp_comments_attachments ->
        ILP.update_ilp_comment_attachment_positions(attachments_ids)
    end
    |> case do
      :ok -> {:noreply, stream_attachments(socket)}
      {:error, msg} -> {:noreply, put_flash(socket, :error, msg)}
    end
  end

  def handle_event(
        "toggle_moment_card_attachment_share",
        %{"attachment_id" => attachment_id, "index" => i},
        socket
      ) do
    # as attachment_id is handled in JS call, validate if it's part of the current attachments
    with true <- attachment_id in socket.assigns.attachments_ids,
         attachment <- Attachments.get_attachment!(attachment_id),
         {:ok, attachment} <- LearningContext.toggle_moment_card_attachment_share(attachment) do
      notify(__MODULE__, {:updated, attachment}, socket.assigns)
      {:noreply, stream_insert(socket, :attachments, {attachment, i})}
    else
      _ ->
        {:noreply, put_flash(socket, :error, gettext("Something went wrong"))}
    end
  end

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
          base_url = SupabaseHelpers.config()[:base_url]
          attachment_url = "#{base_url}/storage/v1/object/public/#{URI.encode(object.key)}"

          {:ok, {:ok, {attachment_url, entry.client_name}}}

        {:error, %{message: message}} ->
          {:ok, {:error, message}}
      end
    end)
    |> hd()
    |> case do
      {:ok, {link, name}} -> save_attachment(socket, :new, %{"name" => name, "link" => link})
      {:error, message} -> {:noreply, assign(socket, :upload_error, message)}
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

  defp save_attachment(%{assigns: %{type: :note_attachments}} = socket, :new, params) do
    %{
      current_user: current_user,
      note_id: note_id
    } = socket.assigns

    case Notes.create_note_attachment(current_user, note_id, params) do
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

  defp save_attachment(%{assigns: %{type: :moment_card_attachments}} = socket, :new, params) do
    %{
      current_user: current_user,
      moment_card_id: moment_card_id
    } = socket.assigns

    case LearningContext.create_moment_card_attachment(
           current_user.current_profile_id,
           moment_card_id,
           params,
           socket.assigns.shared_with_student || false
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

  defp save_attachment(%{assigns: %{type: :ilp_comments_attachments}} = socket, :new, params) do
    params = Map.put(params, "ilp_comment_id", socket.assigns.ilp_comment_id)

    case ILP.create_ilp_comment_attachment(params) do
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

  defp save_attachment(%{assigns: %{type: :ilp_comments_attachments}} = socket, :edit, params) do
    params = Map.put(params, "ilp_comment_id", socket.assigns.ilp_comment_id)

    case ILP.update_ilp_comment_attachment(socket.assigns.attachment, params) do
      {:ok, attachment} ->
        socket =
          socket
          |> assign(:is_adding_external, false)
          |> assign(:is_editing, false)
          |> stream_attachments()

        notify(__MODULE__, {:edited, attachment}, socket.assigns)

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
