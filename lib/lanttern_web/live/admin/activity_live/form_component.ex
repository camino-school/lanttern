defmodule LantternWeb.Admin.ActivityLive.FormComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias LantternWeb.CurriculumLive.CurriculumItemSearchComponent
  import LantternWeb.LearningContextHelpers
  import LantternWeb.TaxonomyHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage activity records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="activity-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:strand_id]}
          type="select"
          label="Strand"
          prompt="Select strand"
          options={@strand_options}
        />
        <.input
          field={@form[:subjects_ids]}
          type="select"
          label="Subjects"
          prompt="Select subjects"
          options={@subject_options}
          multiple
        />
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:position]} type="number" label="Position" />
        <.live_component
          module={CurriculumItemSearchComponent}
          id="curriculum-item-search"
          notify_component={@myself}
          refocus_on_select="true"
        />
        <div
          :for={curriculum_item <- @curriculum_items}
          id={"curriculum-item-#{curriculum_item.id}"}
          class="flex items-start p-4 rounded bg-white shadow-lg"
        >
          <div class="flex-1 text-sm">
            <span class="block mb-1 text-xs font-bold">
              <%= "##{curriculum_item.id} #{curriculum_item.curriculum_component.name}" %>
            </span>
            <%= curriculum_item.name %>
          </div>
          <button
            type="button"
            class="shrink-0 p-1 rounded-full bg-ltrn-hairline"
            phx-click={JS.push("remove_curriculum_item", value: %{id: curriculum_item.id})}
            phx-target={@myself}
          >
            <.icon name="hero-x-mark" />
          </button>
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Save Activity</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:curriculum_items, [])
     |> assign(:strand_options, generate_strand_options())
     |> assign(:subject_options, generate_subject_options())}
  end

  @impl true
  def update(%{activity: activity} = assigns, socket) do
    changeset =
      activity
      |> set_virtual_fields()
      |> LearningContext.change_activity()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       :curriculum_items,
       activity.curriculum_items
       |> Enum.map(& &1.curriculum_item)
     )
     |> assign_form(changeset)}
  end

  def update(%{action: {CurriculumItemSearchComponent, {:selected, curriculum_item}}}, socket) do
    {:ok,
     socket
     |> update(:curriculum_items, &(&1 ++ [curriculum_item]))}
  end

  defp set_virtual_fields(activity) do
    activity
    |> Map.put(:subjects_ids, activity.subjects |> Enum.map(& &1.id))
  end

  # event handlers

  @impl true
  def handle_event("remove_curriculum_item", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> update(:curriculum_items, &Enum.filter(&1, fn ci -> ci.id != id end))}
  end

  def handle_event("validate", %{"activity" => activity_params}, socket) do
    changeset =
      socket.assigns.activity
      |> LearningContext.change_activity(activity_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"activity" => activity_params}, socket) do
    # add curriculum_items to params
    activity_params =
      activity_params
      |> Map.put(
        "curriculum_items",
        socket.assigns.curriculum_items
        |> Enum.map(&%{curriculum_item_id: &1.id})
      )

    save_activity(socket, socket.assigns.action, activity_params)
  end

  defp save_activity(socket, :edit, activity_params) do
    case LearningContext.update_activity(socket.assigns.activity, activity_params,
           preloads: [:strand, curriculum_items: :curriculum_item]
         ) do
      {:ok, activity} ->
        notify_parent({:saved, activity})

        {:noreply,
         socket
         |> put_flash(:info, "Activity updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_activity(socket, :new, activity_params) do
    case LearningContext.create_activity(activity_params,
           preloads: [:strand, :subjects, curriculum_items: :curriculum_item]
         ) do
      {:ok, activity} ->
        notify_parent({:saved, activity})

        {:noreply,
         socket
         |> put_flash(:info, "Activity created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
