defmodule LantternWeb.LearningContext.ActivityFormComponent do
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
      <.form
        for={@form}
        id="activity-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%= if @is_admin do %>
          <.input
            field={@form[:strand_id]}
            type="select"
            label="Strand"
            prompt="Select strand"
            options={@strand_options}
            class="mb-6"
          />
        <% else %>
          <.input field={@form[:strand_id]} type="hidden" />
        <% end %>
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
          id="activity-subjects-select"
          field={@form[:subject_id]}
          multi_field={:subjects_ids}
          options={@subject_options}
          selected_ids={@selected_subjects_ids}
          label="Subjects"
          prompt="Select subject"
          empty_message="No subject selected"
          notify_component={@myself}
        />
        <div :if={@is_admin} class="mt-6">
          <.input field={@form[:position]} type="number" label="Position" class="mb-6" />
          <div class="flex justify-end">
            <.button type="submit" phx-disable-with="Saving...">Save activity</.button>
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
  def update(%{activity: activity, is_admin: true} = assigns, socket) do
    selected_subjects_ids = activity.subjects |> Enum.map(& &1.id)

    changeset = LearningContext.change_activity(activity)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_subjects_ids, selected_subjects_ids)
     |> assign(:strand_options, generate_strand_options())
     |> assign(:subject_options, generate_subject_options())
     |> assign_form(changeset)}
  end

  def update(%{activity: activity} = assigns, socket) do
    selected_subjects_ids = activity.subjects |> Enum.map(& &1.id)

    changeset = LearningContext.change_activity(activity)

    subject_options =
      Taxonomy.list_strand_subjects(activity.strand_id)
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
  def handle_event("validate", %{"activity" => activity_params}, socket) do
    changeset =
      socket.assigns.activity
      |> LearningContext.change_activity(activity_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"activity" => activity_params}, socket) do
    # add subjects_ids to params
    activity_params =
      activity_params
      |> Map.put("subjects_ids", socket.assigns.selected_subjects_ids)

    save_activity(socket, socket.assigns.action, activity_params)
  end

  defp save_activity(socket, :edit, activity_params) do
    case LearningContext.update_activity(socket.assigns.activity, activity_params,
           preloads: socket.assigns.save_preloads
         ) do
      {:ok, activity} ->
        notify_parent(__MODULE__, {:saved, activity}, socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, "Activity updated successfully")
         |> handle_navigation(activity)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_activity(socket, :new, activity_params) do
    case LearningContext.create_activity(activity_params,
           preloads: socket.assigns.save_preloads
         ) do
      {:ok, activity} ->
        notify_parent(__MODULE__, {:saved, activity}, socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, "Activity created successfully")
         |> handle_navigation(activity)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # helpers

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
