defmodule LantternWeb.LearningContext.StrandFormComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias LantternWeb.SupabaseHelpers
  import LantternWeb.TaxonomyHelpers

  # live components
  alias LantternWeb.Form.MultiSelectComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id="strand-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <.error_block :if={@form.source.action == :insert} class="mb-6">
          <%= gettext("Oops, something went wrong! Please check the errors below.") %>
        </.error_block>
        <div
          :if={!@strand.cover_image_url || @is_replacing_cover}
          class={[
            "p-4 border border-dashed border-ltrn-lighter rounded-md mb-6 text-center text-ltrn-subtle",
            if(@uploads.cover.entries != [], do: "hidden")
          ]}
          phx-drop-target={@uploads.cover.ref}
        >
          <div>
            <.icon name="hero-photo" class="h-10 w-10 mx-auto mb-6" />
            <div>
              <label
                for={@uploads.cover.ref}
                class="cursor-pointer text-ltrn-primary hover:text-ltrn-dark focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-ltrn-dark"
              >
                <span><%= gettext("Upload a cover image file") %></span>
                <.live_file_input upload={@uploads.cover} class="sr-only" />
              </label>
              <span><%= gettext("or drag and drop here") %></span>
              <button
                :if={@is_replacing_cover}
                type="button"
                phx-click="cancel-replace-cover"
                phx-target={@myself}
                class="mt-4"
              >
                <%= gettext("Cancel cover replacement") %>
              </button>
            </div>
          </div>
        </div>
        <div :if={@strand.cover_image_url && !@is_replacing_cover} class="relative mb-6">
          <div class="flex items-center justify-center w-full h-60 bg-ltrn-subtle overflow-hidden">
            <img src={@strand.cover_image_url} alt="Cover image" class="w-full" />
          </div>
          <.icon_button
            type="button"
            name="hero-x-mark"
            theme="white"
            rounded
            phx-click="replace-cover"
            sr_text={gettext("Replace image")}
            class="absolute top-2 right-2"
            phx-target={@myself}
          />
        </div>
        <div :for={entry <- @uploads.cover.entries} class="relative mb-6">
          <div
            :if={entry.valid?}
            class="flex items-center justify-center w-full h-60 bg-ltrn-subtle overflow-hidden"
          >
            <.live_img_preview entry={entry} class="w-full" />
          </div>
          <.error_block :if={!entry.valid?} class="p-6 border border-red-500 rounded">
            <p><%= gettext("File \"%{file}\" is invalid.", file: entry.client_name) %></p>
            <%= for err <- upload_errors(@uploads.cover, entry) do %>
              <%= error_to_string(@uploads.cover, err) %>
            <% end %>
          </.error_block>
          <.icon_button
            type="button"
            name="hero-x-mark"
            theme="white"
            rounded
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            sr_text={gettext("cancel")}
            class="absolute top-2 right-2"
            phx-target={@myself}
          />
        </div>
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Name")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.input
          field={@form[:type]}
          type="text"
          label={gettext("Type")}
          class="mb-6"
          phx-debounce="1500"
          help_text={gettext("E.g. project, unit, course, etc.")}
          show_optional
        />
        <.input
          field={@form[:description]}
          type="textarea"
          label={gettext("Description")}
          class="mb-1"
          phx-debounce="1500"
        />
        <.markdown_supported class="mb-6" />
        <.live_component
          module={MultiSelectComponent}
          id="strand-subjects-select"
          field={@form[:subject_id]}
          multi_field={:subjects_ids}
          options={@subject_options}
          selected_ids={@selected_subjects_ids}
          label={gettext("Subjects")}
          prompt={gettext("Select subject")}
          empty_message={gettext("No subject selected")}
          class="mb-6"
          notify_component={@myself}
        />
        <.live_component
          module={MultiSelectComponent}
          id="strand-years-select"
          field={@form[:year_id]}
          multi_field={:years_ids}
          options={@year_options}
          selected_ids={@selected_years_ids}
          label={gettext("Years")}
          prompt={gettext("Select year")}
          empty_message={gettext("No year selected")}
          class="mb-6"
          notify_component={@myself}
        />
        <div :if={@show_actions} class="flex justify-end mt-6">
          <.button type="submit" phx-disable-with={gettext("Saving...")}>
            <%= gettext("Save Strand") %>
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:class, nil)
     |> assign(:show_actions, false)
     |> assign(:subject_options, generate_subject_options())
     |> assign(:year_options, generate_year_options())
     |> assign(:is_replacing_cover, false)
     |> allow_upload(:cover,
       accept: ~w(.jpg .jpeg .png),
       max_file_size: 1_000_000,
       max_entries: 1
     )}
  end

  @impl true
  def update(%{strand: strand} = assigns, socket) do
    selected_subjects_ids = strand.subjects |> Enum.map(& &1.id)
    selected_years_ids = strand.years |> Enum.map(& &1.id)
    changeset = LearningContext.change_strand(strand)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_subjects_ids, selected_subjects_ids)
     |> assign(:selected_years_ids, selected_years_ids)
     |> assign_form(changeset)}
  end

  def update(%{action: {MultiSelectComponent, {:change, :subjects_ids, ids}}}, socket) do
    {:ok, assign(socket, :selected_subjects_ids, ids)}
  end

  def update(%{action: {MultiSelectComponent, {:change, :years_ids, ids}}}, socket) do
    {:ok, assign(socket, :selected_years_ids, ids)}
  end

  # event handlers

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :cover, ref)}
  end

  def handle_event("replace-cover", _, socket) do
    {:noreply, assign(socket, :is_replacing_cover, true)}
  end

  def handle_event("cancel-replace-cover", _, socket) do
    {:noreply, assign(socket, :is_replacing_cover, false)}
  end

  def handle_event("validate", %{"strand" => strand_params}, socket) do
    changeset =
      socket.assigns.strand
      |> LearningContext.change_strand(strand_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"strand" => strand_params}, socket) do
    cover_image_url =
      consume_uploaded_entries(socket, :cover, fn %{path: file_path}, entry ->
        {:ok, object} =
          SupabaseHelpers.upload_object(
            "covers",
            "#{Ecto.UUID.generate()}-#{entry.client_name}",
            file_path,
            %{content_type: entry.client_type}
          )

        image_url =
          "#{SupabaseHelpers.config().base_url}/storage/v1/object/public/#{URI.encode(object["Key"])}"

        {:ok, image_url}
      end)
      |> case do
        [] -> nil
        [image_url] -> image_url
      end

    # add cover, subjects_ids, and years_ids to params
    strand_params =
      strand_params
      |> Map.put("cover_image_url", cover_image_url || socket.assigns.strand.cover_image_url)
      |> Map.put("subjects_ids", socket.assigns.selected_subjects_ids)
      |> Map.put("years_ids", socket.assigns.selected_years_ids)

    save_strand(socket, socket.assigns.action, strand_params)
  end

  defp save_strand(socket, :edit, strand_params) do
    case LearningContext.update_strand(socket.assigns.strand, strand_params) do
      {:ok, strand} ->
        notify_parent(__MODULE__, {:saved, strand}, socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Strand updated successfully"))
         |> handle_navigation(strand)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_strand(socket, :new, strand_params) do
    case LearningContext.create_strand(strand_params,
           preloads: [:subjects, :years]
         ) do
      {:ok, strand} ->
        notify_parent(__MODULE__, {:saved, strand}, socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Strand created successfully"))
         |> handle_navigation(strand)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # helpers

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
