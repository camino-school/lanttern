defmodule LantternWeb.AssessmentPointLive.DifferentiationRubricComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric
  alias LantternWeb.RubricsLive.FormComponent, as: RubricsFormComponent

  def render(assigns) do
    ~H"""
    <div id={"entry-#{@entry.id}-differentiation-panel"} role="tabpanel" class="mt-6 hidden">
      <.form
        id={"entry-#{@entry.id}-rubric-form"}
        for={@form}
        class="flex items-end gap-2"
        phx-change="rubric_selected"
        phx-submit="save_rubric"
        phx-target={@myself}
      >
        <.input
          field={@form[:rubric_id]}
          type="select"
          label="Rubric"
          options={@rubric_options}
          prompt="No differentiation rubric"
          class="flex-1"
        />
        <.button
          type="submit"
          disabled={!@has_rubric_change || @is_creating_rubric}
          class={["shrink-0", if(!@has_rubric_change || @is_creating_rubric, do: "hidden")]}
        >
          Save
        </.button>
      </.form>
      <%= if @is_creating_rubric do %>
        <.live_component
          module={RubricsFormComponent}
          id={"entry-#{@entry.id}"}
          action={:new}
          rubric={
            %Rubric{
              scale_id: @entry.scale_id,
              is_differentiation: true
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
        <section class="mt-8">
          <h5 class="-mb-2 font-display font-black text-lg text-ltrn-subtle">
            Differentiation descriptors
          </h5>
          <.rubric_descriptors descriptors={@rubric.descriptors} class="mt-6" />
        </section>
      <% end %>
    </div>
    """
  end

  # function components

  attr :descriptors, :list, required: true
  attr :class, :any, default: nil

  defp rubric_descriptors(assigns) do
    ~H"""
    <div :for={descriptor <- @descriptors} class={@class}>
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
    """
  end

  # lifecycle

  def mount(socket) do
    {:ok,
     socket
     |> assign(:is_creating_rubric, false)
     |> assign(:has_rubric_change, false)}
  end

  def update(%{entry: entry} = assigns, socket) do
    # this is N+1, but it's *kind of* ok because we
    # don't expect too many diff rubrics in a real scenario
    rubric =
      case entry.differentiation_rubric_id do
        nil -> nil
        rubric_id -> Rubrics.get_full_rubric!(rubric_id)
      end

    form =
      %{"rubric_id" => entry.differentiation_rubric_id}
      |> to_form(as: :entry_rubric)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:rubric, rubric)
     |> assign(:form, form)}
  end

  def update(%{action: {RubricsFormComponent, {:created, rubric}}}, socket) do
    entry = socket.assigns.entry

    entry
    |> Assessments.update_assessment_point_entry(%{
      differentiation_rubric_id: rubric.id
    })
    |> case do
      {:ok, assessment_point_entry} ->
        notify_component(
          socket.assigns.notify_component,
          {:new_diff_rubric_linked, assessment_point_entry.id, rubric}
        )

        {:ok,
         socket
         |> assign(:rubric, Rubrics.get_full_rubric!(rubric.id))
         |> assign(:form, to_form(%{"rubric_id" => rubric.id}, as: :entry_rubric))
         |> assign(:is_creating_rubric, false)
         |> assign(:has_rubric_change, false)}

      {:error, _changeset} ->
        notify_parent({:error, "Couldn't link rubric to assessment point"})
        {:ok, socket}
    end
  end

  # event handlers

  def handle_event("rubric_selected", %{"entry_rubric" => %{"rubric_id" => ""}}, socket) do
    has_rubric_change = socket.assigns.entry.differentiation_rubric_id != nil

    {:noreply,
     socket
     |> assign(:rubric, nil)
     |> assign(:has_rubric_change, has_rubric_change)
     |> assign(:is_creating_rubric, false)
     |> assign(:form, to_form(%{"rubric_id" => ""}, as: :entry_rubric))}
  end

  def handle_event("rubric_selected", %{"entry_rubric" => %{"rubric_id" => "new"}}, socket) do
    {:noreply,
     socket
     |> assign(:is_creating_rubric, true)
     |> assign(:form, to_form(%{"rubric_id" => "new"}, as: :entry_rubric))}
  end

  def handle_event("rubric_selected", %{"entry_rubric" => %{"rubric_id" => rubric_id}}, socket) do
    has_rubric_change = rubric_id != "#{socket.assigns.entry.differentiation_rubric_id}"

    {:noreply,
     socket
     |> assign(:rubric, Rubrics.get_full_rubric!(rubric_id))
     |> assign(:has_rubric_change, has_rubric_change)
     |> assign(:is_creating_rubric, false)
     |> assign(:form, to_form(%{"rubric_id" => "new"}, as: :entry_rubric))}
  end

  def handle_event("save_rubric", %{"entry_rubric" => %{"rubric_id" => rubric_id}}, socket) do
    rubric_id = if rubric_id == "", do: nil, else: rubric_id

    socket.assigns.entry
    |> Assessments.update_assessment_point_entry(%{
      differentiation_rubric_id: rubric_id
    })
    |> case do
      {:ok, assessment_point_entry} ->
        notify_component(
          socket.assigns.notify_component,
          {:diff_rubric_linked, assessment_point_entry.id, rubric_id}
        )

        socket =
          socket
          |> assign(:has_rubric_change, false)
          |> assign(:is_creating_rubric, false)

        {:noreply, socket}

      {:error, _changeset} ->
        notify_parent({:error, "Couldn't link differentiation rubric to assessment point entry"})
        {:noreply, socket}
    end
  end

  # helpers

  defp notify_component(cid, msg), do: send_update(cid, action: {__MODULE__, msg})

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
