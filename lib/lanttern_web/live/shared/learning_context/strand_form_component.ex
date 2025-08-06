defmodule LantternWeb.LearningContext.StrandFormComponent do
  @moduledoc """
  Renders a `Strand` form
  """

  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.SupabaseHelpers
  import LantternWeb.TaxonomyHelpers

  # live components
  alias LantternWeb.Form.MultiSelectComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id="strand-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <.error_block :if={@form.source.action == :insert} class="mb-6">
          {gettext("Oops, something went wrong! Please check the errors below.")}
        </.error_block>
        <.image_field
          current_image_url={@strand.cover_image_url}
          is_removing={@is_removing_cover}
          upload={@uploads.cover}
          on_cancel_replace={JS.push("cancel-replace-cover", target: @myself)}
          on_cancel_upload={JS.push("cancel-upload", target: @myself)}
          on_replace={JS.push("replace-cover", target: @myself)}
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
          type="markdown"
          label={gettext("Description")}
          class="mb-6"
          phx-debounce="1500"
        />
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
        <div class="p-4 rounded-xs mb-6 bg-ltrn-staff-lightest">
          <.input
            field={@form[:teacher_instructions]}
            type="markdown"
            label={gettext("Teacher instructions")}
            show_optional
            phx-debounce="1500"
          />
        </div>
        <div :if={@show_actions} class="flex justify-end mt-6">
          <.button type="submit" phx-disable-with={gettext("Saving...")}>
            {gettext("Save Strand")}
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:show_actions, false)
      |> assign(:subject_options, generate_subject_options())
      |> assign(:year_options, generate_year_options())
      |> assign(:is_removing_cover, false)
      |> allow_upload(:cover,
        accept: ~w(.jpg .jpeg .png .webp),
        max_file_size: 5_000_000,
        max_entries: 1
      )

    {:ok, socket}
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
    {:noreply, assign(socket, :is_removing_cover, true)}
  end

  def handle_event("cancel-replace-cover", _, socket) do
    {:noreply, assign(socket, :is_removing_cover, false)}
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
            entry.client_name,
            file_path,
            %{content_type: entry.client_type}
          )

        image_url =
          "#{SupabaseHelpers.config().base_url}/storage/v1/object/public/#{URI.encode(object.key)}"

        {:ok, image_url}
      end)
      |> case do
        [] -> nil
        [image_url] -> image_url
      end

    # besides "consumed" cover image, we should also consider is_removing_cover flag
    cover_image_url =
      cond do
        cover_image_url -> cover_image_url
        socket.assigns.is_removing_cover -> nil
        true -> socket.assigns.strand.cover_image_url
      end

    # add cover, subjects_ids, and years_ids to params
    strand_params =
      strand_params
      |> Map.put("cover_image_url", cover_image_url)
      |> Map.put("subjects_ids", socket.assigns.selected_subjects_ids)
      |> Map.put("years_ids", socket.assigns.selected_years_ids)

    save_strand(socket, socket.assigns.strand, strand_params)
  end

  defp save_strand(socket, %{id: strand_id}, strand_params) when not is_nil(strand_id) do
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

  defp save_strand(socket, %{id: nil}, strand_params) do
    case LearningContext.create_strand(strand_params,
           preloads: [:subjects, :years]
         ) do
      {:ok, strand} ->
        notify_parent(__MODULE__, {:saved, strand}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Strand created successfully"))
          |> handle_navigation(strand)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # helpers

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
