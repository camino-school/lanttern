defmodule LantternWeb.RubricLive.FormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Rubrics
  alias Lanttern.Grading
  import LantternWeb.GradingHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage rubric records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="rubric-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:criteria]} type="text" label="Criteria" />
        <.input
          field={@form[:scale_id]}
          type="select"
          label="Scale"
          options={@scale_options}
          prompt="Select scale"
          phx-target={@myself}
          phx-change="scale_selected"
        />
        <.input field={@form[:is_differentiation]} type="checkbox" label="Is differentiation" />
        <.inputs_for :let={ef} field={@form[:descriptors]}>
          <.input type="hidden" field={ef[:scale_id]} />
          <.input type="hidden" field={ef[:scale_type]} />
          <.input type="hidden" field={ef[:ordinal_value_id]} />
          <.input
            type="textarea"
            field={ef[:descriptor]}
            label={Enum.at(@ordinal_values, ef.index).name}
          />
        </.inputs_for>
        <:actions>
          <.button phx-disable-with="Saving...">Save Rubric</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    scale_options = generate_scale_options()

    socket =
      socket
      |> assign(:scale_options, scale_options)
      |> assign(:ordinal_values, [])

    {:ok, socket}
  end

  @impl true
  def update(%{rubric: rubric} = assigns, socket) do
    changeset = Rubrics.change_rubric(rubric)
    ordinal_values = Grading.list_ordinal_values(scale_id: rubric.scale_id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:ordinal_values, ordinal_values)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("scale_selected", %{"rubric" => %{"scale_id" => scale_id}}, socket) do
    ordinal_values = Grading.list_ordinal_values(scale_id: scale_id)

    descriptors =
      ordinal_values
      |> Enum.map(
        &%{
          scale_id: &1.scale_id,
          scale_type: "ordinal",
          ordinal_value_id: &1.id,
          descriptor: "—"
        }
      )

    changeset =
      socket.assigns.rubric
      |> Rubrics.change_rubric(
        socket.assigns.form.params
        |> Map.put("descriptors", descriptors)
      )

    socket =
      socket
      |> assign(:ordinal_values, ordinal_values)
      |> assign_form(changeset)

    {:noreply, socket}
  end

  def handle_event("validate", %{"rubric" => rubric_params}, socket) do
    changeset =
      socket.assigns.rubric
      |> Rubrics.change_rubric(rubric_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"rubric" => rubric_params}, socket) do
    save_rubric(socket, socket.assigns.action, rubric_params)
  end

  defp save_rubric(socket, :edit, rubric_params) do
    case Rubrics.update_rubric(socket.assigns.rubric, rubric_params, preloads: :scale) do
      {:ok, rubric} ->
        notify_parent({:saved, rubric})

        {:noreply,
         socket
         |> put_flash(:info, "Rubric updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_rubric(socket, :new, rubric_params) do
    case Rubrics.create_rubric(rubric_params, preloads: :scale) do
      {:ok, rubric} ->
        notify_parent({:saved, rubric})

        {:noreply,
         socket
         |> put_flash(:info, "Rubric created successfully")
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
