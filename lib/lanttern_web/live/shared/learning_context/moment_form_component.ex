defmodule LantternWeb.LearningContext.MomentFormComponent do
  @moduledoc """
  Renders a `Moment` form
  """

  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  import LantternWeb.LearningContextHelpers
  alias Lanttern.Taxonomy
  import LantternWeb.TaxonomyHelpers

  # live components
  alias LantternWeb.Form.MultiSelectComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id="moment-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <%= if @is_admin do %>
          <.input
            field={@form[:strand_id]}
            type="select"
            label={gettext("Strand")}
            prompt={gettext("Select strand")}
            options={@strand_options}
            class="mb-6"
          />
        <% else %>
          <.input field={@form[:strand_id]} type="hidden" />
        <% end %>
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Name")}
          class="mb-6"
          phx-debounce="1500"
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
          id="moment-subjects-select"
          field={@form[:subject_id]}
          multi_field={:subjects_ids}
          options={@subject_options}
          selected_ids={@selected_subjects_ids}
          label={gettext("Subjects")}
          prompt={gettext("Select subject")}
          empty_message={gettext("No subject selected")}
          notify_component={@myself}
        />
        <div :if={@is_admin} class="mt-6">
          <.input field={@form[:position]} type="number" label={gettext("Position")} class="mb-6" />
          <div class="flex justify-end">
            <.button type="submit" phx-disable-with={gettext("Saving...")}>
              {gettext("Save moment")}
            </.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:class, nil)
     |> assign(:save_preloads, [])
     |> assign(:is_admin, false)}
  end

  @impl true
  def update(%{moment: moment, is_admin: true} = assigns, socket) do
    selected_subjects_ids = moment.subjects |> Enum.map(& &1.id)

    changeset = LearningContext.change_moment(moment)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_subjects_ids, selected_subjects_ids)
     |> assign(:strand_options, generate_strand_options())
     |> assign(:subject_options, generate_subject_options())
     |> assign_form(changeset)}
  end

  def update(%{moment: moment} = assigns, socket) do
    selected_subjects_ids = moment.subjects |> Enum.map(& &1.id)

    changeset = LearningContext.change_moment(moment)

    subject_options =
      Taxonomy.list_strand_subjects(moment.strand_id)
      |> Enum.map(&{&1.name, &1.id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_subjects_ids, selected_subjects_ids)
     |> assign(:subject_options, subject_options)
     |> assign_form(changeset)}
  end

  def update(%{action: {MultiSelectComponent, {:change, :subjects_ids, ids}}}, socket) do
    {:ok, assign(socket, :selected_subjects_ids, ids)}
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"moment" => moment_params}, socket) do
    changeset =
      socket.assigns.moment
      |> LearningContext.change_moment(moment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"moment" => moment_params}, socket) do
    # add subjects_ids to params
    moment_params =
      moment_params
      |> Map.put("subjects_ids", socket.assigns.selected_subjects_ids)

    save_moment(socket, socket.assigns.moment.id, moment_params)
  end

  defp save_moment(socket, nil, moment_params) do
    case LearningContext.create_moment(moment_params,
           preloads: socket.assigns.save_preloads
         ) do
      {:ok, moment} ->
        notify_parent(__MODULE__, {:saved, moment}, socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Moment created successfully"))
         |> handle_navigation(moment)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_moment(socket, _id, moment_params) do
    case LearningContext.update_moment(socket.assigns.moment, moment_params,
           preloads: socket.assigns.save_preloads
         ) do
      {:ok, moment} ->
        notify_parent(__MODULE__, {:saved, moment}, socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Moment updated successfully"))
         |> handle_navigation(moment)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # helpers

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
