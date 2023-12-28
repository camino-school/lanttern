defmodule LantternWeb.LearningContext.StrandFormComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.Curricula
  import LantternWeb.TaxonomyHelpers

  # live components
  alias LantternWeb.Curricula.CurriculumItemSearchComponent
  alias LantternWeb.Form.MultiSelectComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id="strand-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <.error_block :if={@form.source.action == :insert} class="mb-6">
          Oops, something went wrong! Please check the errors below.
        </.error_block>
        <div
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
                <span>Upload a cover image file</span>
                <.live_file_input upload={@uploads.cover} class="sr-only" />
              </label>
              <span>or drag and drop here</span>
            </div>
          </div>
        </div>
        <div :for={entry <- @uploads.cover.entries} class="relative mb-6">
          <div
            :if={entry.valid?}
            class="flex items-center justify-center w-full h-60 bg-ltrn-subtle overflow-hidden"
          >
            <.live_img_preview entry={entry} class="w-full" />
          </div>
          <.error_block :if={!entry.valid?} class="p-6 border border-red-500 rounded">
            <p><%= "File \"#{entry.client_name}\" is invalid." %></p>
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
            sr_text="cancel"
            class="absolute top-2 right-2"
            phx-target={@myself}
          />
        </div>
        <.input field={@form[:name]} type="text" label="Name" class="mb-6" phx-debounce="1500" />
        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
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
          label="Subjects"
          prompt="Select subject"
          empty_message="No subject selected"
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
          label="Years"
          prompt="Select year"
          empty_message="No year selected"
          class="mb-6"
          notify_component={@myself}
        />
        <.live_component
          module={CurriculumItemSearchComponent}
          id="curriculum-item-search"
          notify_component={@myself}
          refocus_on_select="true"
          label="Curriculum"
        />
        <div
          :for={{curriculum_item, i} <- @curriculum_items}
          id={"curriculum-item-#{curriculum_item.id}"}
          class="flex items-center gap-4 mt-6"
        >
          <div class="flex-1 flex items-start p-4 rounded bg-white shadow-lg">
            <div class="flex-1 text-sm">
              <span class="block mb-1 text-xs font-bold">
                <%= "##{curriculum_item.id} #{curriculum_item.curriculum_component.name}" %>
              </span>
              <%= curriculum_item.name %>
            </div>
            <.icon_button
              type="button"
              sr_text="Remove curriculum item"
              name="hero-x-mark-mini"
              theme="ghost"
              rounded
              size="sm"
              phx-click={JS.push("remove_curriculum_item", value: %{id: curriculum_item.id})}
              phx-target={@myself}
            />
          </div>
          <div class="shrink-0 flex flex-col gap-2">
            <.icon_button
              type="button"
              sr_text="Move curriculum item up"
              name="hero-chevron-up-mini"
              theme="ghost"
              rounded
              size="sm"
              disabled={i == 0}
              phx-click={JS.push("curriculum_item_position", value: %{from: i, to: i - 1})}
              phx-target={@myself}
            />
            <.icon_button
              type="button"
              sr_text="Move curriculum item down"
              name="hero-chevron-down-mini"
              theme="ghost"
              rounded
              size="sm"
              disabled={i + 1 == length(@curriculum_items)}
              phx-click={JS.push("curriculum_item_position", value: %{from: i, to: i + 1})}
              phx-target={@myself}
            />
          </div>
        </div>
        <div :if={@show_actions} class="flex justify-end mt-6">
          <.button type="submit" phx-disable-with="Saving...">Save Strand</.button>
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
     |> assign(:curriculum_items, [])
     |> assign(:show_actions, false)
     |> assign(:subject_options, generate_subject_options())
     |> assign(:year_options, generate_year_options())
     |> allow_upload(:cover,
       accept: ~w(.jpg .jpeg .png),
       max_file_size: 3_000_000,
       max_entries: 1,
       external: &supabase_upload/2
     )}
  end

  @impl true
  def update(%{strand: strand} = assigns, socket) do
    selected_subjects_ids = strand.subjects |> Enum.map(& &1.id)
    selected_years_ids = strand.years |> Enum.map(& &1.id)

    curriculum_items =
      case strand.id do
        nil ->
          []

        id ->
          Curricula.list_strand_curriculum_items(id, preloads: :curriculum_component)
          |> Enum.with_index()
      end

    changeset = LearningContext.change_strand(strand)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_subjects_ids, selected_subjects_ids)
     |> assign(:selected_years_ids, selected_years_ids)
     |> assign(:curriculum_items, curriculum_items)
     |> assign_form(changeset)}
  end

  def update(%{action: {MultiSelectComponent, {:change, :subjects_ids, ids}}}, socket) do
    {:ok, assign(socket, :selected_subjects_ids, ids)}
  end

  def update(%{action: {MultiSelectComponent, {:change, :years_ids, ids}}}, socket) do
    {:ok, assign(socket, :selected_years_ids, ids)}
  end

  def update(%{action: {CurriculumItemSearchComponent, {:selected, curriculum_item}}}, socket) do
    curriculum_items =
      socket.assigns.curriculum_items
      |> Enum.find(fn {ci, _i} -> ci.id == curriculum_item.id end)
      |> case do
        nil ->
          socket.assigns.curriculum_items ++
            [{curriculum_item, length(socket.assigns.curriculum_items)}]

        _ ->
          socket.assigns.curriculum_items
      end

    {:ok,
     socket
     |> assign(:curriculum_items, curriculum_items)}
  end

  # event handlers

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :cover, ref)}
  end

  def handle_event("remove_curriculum_item", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> update(:curriculum_items, &Enum.filter(&1, fn {ci, _i} -> ci.id != id end))}
  end

  def handle_event("curriculum_item_position", %{"from" => i, "to" => j}, socket) do
    curriculum_items =
      socket.assigns.curriculum_items
      |> Enum.map(fn {ap, _i} -> ap end)
      |> swap(i, j)
      |> Enum.with_index()

    {:noreply, assign(socket, :curriculum_items, curriculum_items)}
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
      consume_uploaded_entries(socket, :cover, fn %{config: config, fields: fields}, _entry ->
        image_url =
          "#{config.project_url}/storage/v1/object/public/#{fields.bucket}/#{fields.path}"

        {:ok, image_url}
      end)
      |> case do
        [] -> nil
        [image_url] -> image_url
      end

    # add cover, curriculum_items, subjects_ids, and years_ids to params
    strand_params =
      strand_params
      |> Map.put("cover_image_url", cover_image_url)
      |> Map.put("subjects_ids", socket.assigns.selected_subjects_ids)
      |> Map.put("years_ids", socket.assigns.selected_years_ids)
      |> Map.put(
        "curriculum_items",
        socket.assigns.curriculum_items
        |> Enum.map(fn {ci, _i} -> %{curriculum_item_id: ci.id} end)
      )

    save_strand(socket, socket.assigns.action, strand_params)
  end

  defp save_strand(socket, :edit, strand_params) do
    case LearningContext.update_strand(socket.assigns.strand, strand_params,
           preloads: [curriculum_items: :curriculum_item]
         ) do
      {:ok, strand} ->
        notify_parent(__MODULE__, {:saved, strand}, socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, "Strand updated successfully")
         |> handle_navigation(strand)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_strand(socket, :new, strand_params) do
    case LearningContext.create_strand(strand_params,
           preloads: [:subjects, :years, curriculum_items: :curriculum_item]
         ) do
      {:ok, strand} ->
        notify_parent(__MODULE__, {:saved, strand}, socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, "Strand created successfully")
         |> handle_navigation(strand)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # helpers

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  # https://elixirforum.com/t/swap-elements-in-a-list/34471/4
  defp swap(a, i1, i2) do
    e1 = Enum.at(a, i1)
    e2 = Enum.at(a, i2)

    a
    |> List.replace_at(i1, e2)
    |> List.replace_at(i2, e1)
  end

  # based on https://hexdocs.pm/phoenix_live_view/uploads-external.html#direct-to-s3
  defp supabase_upload(entry, socket) do
    config = %{
      project_url: System.fetch_env!("SUPABASE_PROJECT_URL"),
      secret_api_key: System.fetch_env!("SUPABASE_PROJECT_SECRET_API_KEY")
    }

    fields = %{
      bucket: "covers",
      path: "#{Ecto.UUID.generate()}-#{entry.client_name}"
    }

    meta = %{
      uploader: "Supabase",
      config: config,
      fields: fields
    }

    {:ok, meta, socket}
  end
end
