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
  alias Lanttern.ILP.ILPCommentAttachment
  alias Lanttern.SupabaseHelpers

  import Lanttern.Utils, only: [swap: 3]
  import LantternWeb.AttachmentsComponents

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:show_actions, false)
      |> assign(:on_edit_patch, nil)
      |> assign(:create_patch, nil)
      |> assign(:class, nil)
      |> assign(:initialized, false)
      |> assign(:is_adding_external, false)
      |> assign(:is_editing, false)
      |> assign(:allow_editing, true)
      |> stream_configure(
        :attachments,
        dom_id: fn {attachment, _i} -> "attachment-#{attachment.id}" end
      )
      |> allow_upload(:attachment_file,
        accept: :any,
        max_file_size: 5_000_000,
        max_entries: 1
      )
      |> assign(:upload_error, nil)
      |> assign(:attachments_length, 0)
      |> assign(:attachments_ids, nil)

    {:ok, socket}
  end

  defp stream_attachments(%{assigns: %{ilp_comment: %{id: id}}} = socket) when not is_nil(id) do
    attachments = ILP.list_ilp_comment_attachments(id)
    attachments_ids = Enum.map(attachments, & &1.id)

    socket
    |> stream(:attachments, Enum.with_index(attachments), reset: true)
    |> assign(:attachments_length, length(attachments))
    |> assign(:attachments_ids, attachments_ids)
  end

  defp stream_attachments(socket), do: socket

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
        <div id="ilp-comment-attachments">
          <div class={[@class, if(@form_action == :new && @attachments_length == 0, do: "hidden")]}>
            <div :if={@title} class={["flex items-center gap-2"]}>
              <.icon name="hero-paper-clip" class="w-6 h-6" />
              <h5 class="font-display font-bold text-sm"><%= gettext("Attachments") %></h5>
            </div>
            <.attachments_list
              :if={@attachments_length > 0}
              id={"#{@id}-attachments-list"}
              class={if @is_editing, do: "hidden"}
              attachments={@streams.attachments}
              allow_editing={@allow_editing}
              attachments_length={@attachments_length}
              on_move_up={
                fn i ->
                  JS.push("reorder_attachments", value: %{from: i, to: i - 1}, target: @myself)
                end
              }
              on_move_down={
                fn i ->
                  JS.push("reorder_attachments", value: %{from: i, to: i + 1}, target: @myself)
                end
              }
              on_edit={
                fn id ->
                  JS.push("edit", value: %{"id" => id}, target: @myself)
                end
              }
              on_remove={
                fn id ->
                  JS.push("delete_attachment", value: %{"id" => id}, target: @myself)
                end
              }
            />
            <div
              :if={@is_adding_external || @is_editing}
              class="p-4 border border-dashed border-ltrn-subtle rounded-sm mt-4 bg-white shadow-lg"
            >
              <.form
                for={@form_attachment}
                id="external-attachment-form"
                phx-target={@myself}
                phx-change="validate_attachment"
                phx-submit="save_attachment"
              >
                <.input
                  field={@form_attachment[:name]}
                  type="text"
                  label={gettext("Attachment name")}
                  class="mb-6"
                  phx-debounce="1500"
                />
                <.input
                  field={@form_attachment[:link]}
                  type="text"
                  label={gettext("Link")}
                  class="mb-6"
                  phx-debounce="1500"
                />
                <div class="flex justify-end gap-2">
                  <.button
                    type="button"
                    theme="ghost"
                    phx-click="cancel_attachment"
                    phx-target={@myself}
                  >
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
                <.button
                  type="submit"
                  form={"#{@id}-attachments-upload-form"}
                  disabled={!entry.valid?}
                >
                  <%= gettext("Upload") %>
                </.button>
              </div>
            </div>
            <div
              :if={@allow_editing && !@is_adding_external && !@is_editing}
              class={[
                "grid grid-cols-2 gap-2 mt-4",
                if(@uploads.attachment_file.entries != [], do: "hidden")
              ]}
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
        </div>
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
    |> stream_attachments()
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

  def handle_event("cancel_attachment", _params, socket) do
    socket =
      socket
      |> assign(:is_adding_external, false)
      |> assign(:is_editing, false)

    {:noreply, socket}
  end

  def handle_event("validate_attachment", %{"ilp_comment_attachment" => params}, socket) do
    changeset =
      %ILPCommentAttachment{}
      |> ILPCommentAttachment.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form_attachment, to_form(changeset))}
  end

  def handle_event("add_external", _, socket) do
    changeset = ILP.change_ilp_comment_attachment(%ILPCommentAttachment{})

    socket =
      socket
      |> assign(:is_adding_external, true)
      |> assign(:form_attachment, to_form(changeset))

    {:noreply, socket}
  end

  def handle_event("reorder_attachments", %{"from" => i, "to" => j}, socket) do
    socket.assigns.attachments_ids
    |> swap(i, j)
    |> ILP.update_ilp_comment_attachment_positions()
    |> case do
      :ok -> {:noreply, stream_attachments(socket)}
      {:error, msg} -> {:noreply, put_flash(socket, :error, msg)}
    end
  end

  def handle_event("delete", _, socket) do
    case ILP.delete_ilp_comment(socket.assigns.ilp_comment, socket.assigns.current_profile.id) do
      {:ok, ilp_comment} ->
        notify(__MODULE__, {:deleted, ilp_comment}, socket.assigns)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("delete_attachment", params, socket) do
    attachment = ILP.get_ilp_comment_attachment!(params["id"])

    case ILP.delete_ilp_comment_attachment(attachment) do
      {:ok, _attachment} ->
        {:noreply, stream_attachments(socket)}

      {:error, _changeset} ->
        socket = assign(socket, :error_msg, gettext("Error deleting attachment"))

        {:noreply, socket}
    end
  end

  def handle_event("edit", params, socket) do
    attachment = ILP.get_ilp_comment_attachment!(params["id"])
    changeset = ILP.change_ilp_comment_attachment(attachment, %{})

    socket =
      socket
      |> assign(:is_editing, true)
      |> assign(:attachment, attachment)
      |> assign(:form_attachment, to_form(changeset))

    {:noreply, socket}
  end

  def handle_event("save_attachment", %{"ilp_comment_attachment" => params}, socket) do
    case socket.assigns do
      %{is_adding_external: true} ->
        params = Map.put(params, "is_external", true)

        save_attachment(socket, :new, params)

      %{is_editing: true} ->
        save_attachment(socket, :edit, params)
    end
  end

  def handle_event("save", %{"ilp_comment" => comment_params}, socket),
    do: save_ilp_comment(socket, socket.assigns.form_action, comment_params)

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

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment_file, ref)}
  end

  def handle_event("clear_upload_error", _, socket) do
    {:noreply, assign(socket, :upload_error, nil)}
  end

  def handle_event("upload", _params, socket) do
    socket
    |> consume_uploaded_entries(:attachment_file, fn %{path: file_path}, entry ->
      map = %{content_type: entry.client_type}

      case SupabaseHelpers.upload_object("attachments", entry.client_name, file_path, map) do
        {:ok, object} ->
          base_url = SupabaseHelpers.config()[:base_url]
          attachment_url = "#{base_url}/storage/v1/object/public/#{URI.encode(object["Key"])}"

          {:ok, {:ok, {attachment_url, entry.client_name}}}

        {:error, message} ->
          {:ok, {:error, message}}
      end
    end)
    |> hd()
    |> case do
      {:ok, {link, name}} -> save_attachment(socket, :new, %{"name" => name, "link" => link})
      {:error, message} -> {:noreply, assign(socket, :upload_error, message)}
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

    case ILP.update_ilp_comment(socket.assigns.ilp_comment, params, profile_id) do
      {:ok, comment} ->
        notify(__MODULE__, {:updated, comment}, socket.assigns)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_attachment(socket, :new, params) do
    params = Map.put(params, "ilp_comment_id", socket.assigns.ilp_comment.id)

    case ILP.create_ilp_comment_attachment(params) do
      {:ok, _attachment} ->
        socket =
          socket
          |> assign(:is_adding_external, false)
          |> stream_attachments()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_attachment(socket, :edit, params) do
    params = Map.put(params, "ilp_comment_id", socket.assigns.ilp_comment.id)

    case ILP.update_ilp_comment_attachment(socket.assigns.attachment, params) do
      {:ok, _attachment} ->
        socket =
          socket
          |> assign(:is_adding_external, false)
          |> assign(:is_editing, false)
          |> stream_attachments()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
