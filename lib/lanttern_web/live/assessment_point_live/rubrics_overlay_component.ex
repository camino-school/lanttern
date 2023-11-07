defmodule LantternWeb.AssessmentPointLive.RubricsOverlayComponent do
  use LantternWeb, :live_component

  import LantternWeb.RubricsHelpers
  alias Lanttern.Assessments
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric
  alias LantternWeb.RubricsLive.FormComponent, as: RubricsFormComponent

  def render(assigns) do
    ~H"""
    <div>
      <.slide_over
        id="rubrics-overlay"
        show={true}
        on_cancel={JS.patch(~p"/assessment_points/#{@assessment_point.id}")}
      >
        <:title>Assessment point rubrics</:title>
        <form
          id="assessment-point-rubric-form"
          class="flex items-end gap-2"
          phx-submit="save_rubric"
          phx-target={@myself}
        >
          <.input
            field={@assessment_point_rubric_form[:rubric_id]}
            type="select"
            label="Rubric"
            options={@rubric_options}
            prompt="No rubric"
            phx-change="assessment_point_rubric_selected"
            phx-target={@myself}
            class="flex-1"
          />
          <.button
            type="submit"
            disabled={!@has_rubric_change || @is_creating_rubric}
            class={["shrink-0", if(!@has_rubric_change || @is_creating_rubric, do: "hidden")]}
          >
            Save
          </.button>
        </form>
        <%= if @is_creating_rubric do %>
          <.live_component
            module={RubricsFormComponent}
            id={:new}
            action={:new}
            rubric={
              %Rubric{
                scale_id: @assessment_point.scale_id,
                is_differentiation: false
              }
            }
            hide_diff_and_scale
            show_submit
            notify_component={@myself}
            notify_parent={false}
            class="mt-6"
          />
        <% end %>
        <%= if @rubric && !@is_creating_rubric do %>
          <section class="mt-10">
            <h4 class="-mb-2 font-display font-black text-xl text-ltrn-subtle">Descriptors</h4>
            <div :for={descriptor <- @rubric.descriptors} class="mt-8">
              <%= if descriptor.scale_type == "ordinal" do %>
                <.badge style_from_ordinal_value={descriptor.ordinal_value}>
                  <%= descriptor.ordinal_value.name %>
                </.badge>
              <% else %>
                <.badge>
                  <%= descriptor.score %>
                </.badge>
              <% end %>
              <.markdown class="mt-2" text={descriptor.descriptor} />
            </div>
          </section>
          <section class="mt-10">
            <h4 class="-mb-2 font-display font-black text-xl text-ltrn-subtle">Differentiation</h4>
            <div role="tablist" class="flex items-center gap-2 mt-6">
              <.person_tab
                :for={entry <- @entries}
                aria-controls={"student-#{entry.student.id}-differentiation-panel"}
                person={entry.student}
                is_current={entry.student.id == @current_student_id}
                phx-click={JS.push("select_student", value: %{id: entry.student.id})}
                phx-target={@myself}
              />
            </div>
            <div
              :for={entry <- @entries}
              id={"student-#{entry.student.id}-differentiation-panel"}
              role="tabpanel"
              class={["mt-6", if(@current_student_id != entry.student.id, do: "hidden")]}
            >
              <form
                id={"student-#{entry.student.id}-rubric-form"}
                class="flex items-end gap-2"
                phx-submit="save_differentiation_rubric"
                phx-target={@myself}
              >
                <.input
                  field={@students_rubric_forms["#{entry.student.id}"][:rubric_id]}
                  type="select"
                  label="Rubric"
                  options={@rubric_options}
                  prompt="No rubric"
                  phx-change="differentiation_rubric_selected"
                  phx-target={@myself}
                  class="flex-1"
                />
                <%!-- <.button
                  type="submit"
                  disabled={!@has_rubric_change || @is_creating_rubric}
                  class={["shrink-0", if(!@has_rubric_change || @is_creating_rubric, do: "hidden")]}
                >
                  Save
                </.button> --%>
              </form>
            </div>
          </section>
        <% end %>
      </.slide_over>
    </div>
    """
  end

  # lifecycle
  def mount(socket) do
    {:ok,
     socket
     |> assign(:is_creating_rubric, false)
     |> assign(:has_rubric_change, false)}
  end

  def update(%{assessment_point: assessment_point, entries: entries} = assigns, socket) do
    rubric =
      case assessment_point.rubric_id do
        nil -> nil
        rubric_id -> Rubrics.get_full_rubric!(rubric_id)
      end

    rubric_options =
      [
        {"Create new rubric", "new"}
        | generate_rubric_options(
            is_differentiation: false,
            scale_id: assessment_point.scale_id
          )
      ]

    assessment_point_rubric_form =
      %{"rubric_id" => assessment_point.rubric_id}
      |> to_form()

    current_student_id =
      case entries do
        [] -> nil
        [entry | _rest] -> entry.student.id
      end

    students_rubric_forms =
      entries
      |> Enum.map(fn entry ->
        {
          "#{entry.student.id}",
          to_form(%{"rubric_id" => nil})
        }
      end)
      |> Enum.into(%{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:rubric, rubric)
     |> assign(:rubric_options, rubric_options)
     |> assign(:assessment_point_rubric_form, assessment_point_rubric_form)
     |> assign(:students_rubric_forms, students_rubric_forms)
     |> assign(:current_student_id, current_student_id)}
  end

  def update(%{action: {RubricsFormComponent, {:created, rubric}}}, socket) do
    assessment_point = socket.assigns.assessment_point

    assessment_point
    |> Assessments.update_assessment_point(%{
      rubric_id: rubric.id
    })
    |> case do
      {:ok, _assessment_point} ->
        notify_parent({:new_rubric_linked, rubric.id})
        {:ok, socket}

      {:error, _changeset} ->
        notify_parent({:error, "Couldn't link rubric to assessment point"})
        {:ok, socket}
    end
  end

  # event handlers

  def handle_event("assessment_point_rubric_selected", %{"rubric_id" => ""}, socket) do
    has_rubric_change = socket.assigns.assessment_point.rubric_id != nil

    socket =
      socket
      |> assign(:rubric, nil)
      |> assign(:has_rubric_change, has_rubric_change)
      |> assign(:is_creating_rubric, false)

    {:noreply, socket}
  end

  def handle_event("assessment_point_rubric_selected", %{"rubric_id" => "new"}, socket) do
    socket =
      socket
      |> assign(:is_creating_rubric, true)

    {:noreply, socket}
  end

  def handle_event("assessment_point_rubric_selected", %{"rubric_id" => rubric_id}, socket) do
    has_rubric_change = rubric_id != "#{socket.assigns.assessment_point.rubric_id}"

    socket =
      socket
      |> assign(:rubric, Rubrics.get_full_rubric!(rubric_id))
      |> assign(:has_rubric_change, has_rubric_change)
      |> assign(:is_creating_rubric, false)

    {:noreply, socket}
  end

  def handle_event("save_rubric", %{"rubric_id" => rubric_id}, socket) do
    rubric_id = if rubric_id == "", do: nil, else: rubric_id

    socket.assigns.assessment_point
    |> Assessments.update_assessment_point(%{
      rubric_id: rubric_id
    })
    |> case do
      {:ok, _assessment_point} ->
        notify_parent({:rubric_linked, rubric_id})

        socket =
          socket
          |> assign(:has_rubric_change, false)
          |> assign(:is_creating_rubric, false)

        {:noreply, socket}

      {:error, _changeset} ->
        notify_parent({:error, "Couldn't link rubric to assessment point"})
        {:noreply, socket}
    end
  end

  def handle_event("select_student", %{"id" => student_id}, socket) do
    {:noreply, assign(socket, :current_student_id, student_id)}
  end

  def handle_event("differentiation_rubric_selected", params, socket) do
    IO.inspect(params)
    IO.inspect(socket.assigns.students_rubric_forms["#{socket.assigns.current_student_id}"])
    {:noreply, socket}
  end

  # helpers

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
