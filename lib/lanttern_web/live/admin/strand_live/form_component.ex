defmodule LantternWeb.Admin.StrandLive.FormComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias LantternWeb.CurriculumLive.CurriculumItemSearchComponent
  import LantternWeb.TaxonomyHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage strand records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="strand-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:subjects_ids]}
          type="select"
          label="Subjects"
          prompt="Select subjects"
          options={@subject_options}
          multiple
        />
        <.input
          field={@form[:years_ids]}
          type="select"
          label="Years"
          prompt="Select years"
          options={@year_options}
          multiple
        />
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
          <.button phx-disable-with="Saving...">Save Strand</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:curriculum_items, [])
     |> assign(:subject_options, generate_subject_options())
     |> assign(:year_options, generate_year_options())}
  end

  @impl true
  def update(%{strand: strand} = assigns, socket) do
    changeset =
      strand
      |> set_virtual_fields()
      |> LearningContext.change_strand()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       :curriculum_items,
       strand.curriculum_items
       |> Enum.map(& &1.curriculum_item)
     )
     |> assign_form(changeset)}
  end

  def update(%{action: {CurriculumItemSearchComponent, {:selected, curriculum_item}}}, socket) do
    {:ok,
     socket
     |> update(:curriculum_items, &(&1 ++ [curriculum_item]))}
  end

  defp set_virtual_fields(strand) do
    strand
    |> Map.put(:subjects_ids, strand.subjects |> Enum.map(& &1.id))
    |> Map.put(:years_ids, strand.years |> Enum.map(& &1.id))
  end

  # event handlers

  @impl true
  def handle_event("remove_curriculum_item", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> update(:curriculum_items, &Enum.filter(&1, fn ci -> ci.id != id end))}
  end

  def handle_event("validate", %{"strand" => strand_params}, socket) do
    changeset =
      socket.assigns.strand
      |> LearningContext.change_strand(strand_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"strand" => strand_params}, socket) do
    # add curriculum_items to params
    strand_params =
      strand_params
      |> Map.put(
        "curriculum_items",
        socket.assigns.curriculum_items
        |> Enum.map(&%{curriculum_item_id: &1.id})
      )

    save_strand(socket, socket.assigns.action, strand_params)
  end

  defp save_strand(socket, :edit, strand_params) do
    case LearningContext.update_strand(socket.assigns.strand, strand_params,
           preloads: [curriculum_items: :curriculum_item]
         ) do
      {:ok, strand} ->
        notify_parent({:saved, strand})

        {:noreply,
         socket
         |> put_flash(:info, "Strand updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_strand(socket, :new, strand_params) do
    case LearningContext.create_strand(strand_params,
           preloads: [:subjects, :years, curriculum_items: :curriculum_item]
         ) do
      {:ok, strand} ->
        notify_parent({:saved, strand})

        {:noreply,
         socket
         |> put_flash(:info, "Strand created successfully")
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
