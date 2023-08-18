defmodule LantternWeb.AssessmentPointLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Grading

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <h1 class="font-display font-black text-3xl">Assessment point details</h1>
      <div class="flex items-center mt-2 font-display font-bold text-xs text-slate-400">
        <.link patch={~p"/assessment_points"} class="underline">Assessment points</.link>
        <span class="mx-1">/</span>
        <.link patch={~p"/assessment_points/explorer"} class="underline">Explorer</.link>
        <span class="mx-1">/</span>
        <span>Details</span>
      </div>
    </div>
    <div class="container mx-auto lg:max-w-5xl mt-10">
      <.link patch={~p"/assessment_points/explorer"} class="flex items-center text-sm text-slate-400">
        <.icon name="hero-arrow-left-mini" class="text-cyan-400 mr-2" />
        <span class="underline">Back to explorer</span>
      </.link>
      <div class="w-full p-6 mt-4 rounded shadow-xl bg-white">
        <div class="max-w-screen-sm">
          <h2 class="font-display font-black text-2xl"><%= @assessment_point.name %></h2>
          <p :if={@assessment_point.description} class="mt-4 text-sm">
            <%= @assessment_point.description %>
          </p>
        </div>
        <div class="flex items-center mt-10">
          <.icon name="hero-calendar" class="text-rose-500 mr-4" /> Date: <%= @formatted_datetime %>
        </div>
        <div class="flex items-center mt-4">
          <.icon name="hero-bookmark" class="text-rose-500 mr-4" />
          Curriculum: <%= @assessment_point.curriculum_item.name %>
        </div>
        <div class="flex items-center mt-4">
          <.icon name="hero-view-columns" class="text-rose-500 mr-4" />
          Scale: <%= @assessment_point.scale.name %>
          <.ordinal_values ordinal_values={@ordinal_values} />
        </div>
        <div :if={length(@assessment_point.classes) > 0} class="flex items-center mt-4">
          <.icon name="hero-squares-2x2" class="text-rose-500 mr-4" /> Classes:
          <.classes classes={@assessment_point.classes} />
        </div>
        <div class="mt-20">
          <div class="flex items-center gap-2">
            <div class="shrink-0 w-1/4"></div>
            <div class={[
              "flex items-center font-display font-bold text-slate-400",
              if(
                @assessment_point.scale.type == "ordinal",
                do: "flex-[2_0]",
                else: "flex-[1_0]"
              )
            ]}>
              <.icon name="hero-view-columns" class="mr-4" /> Marking
            </div>
            <div class="flex-[2_0] items-center font-display font-bold text-slate-400">
              <.icon name="hero-pencil-square" class="mr-4" /> Notes and observations
            </div>
          </div>
          <.live_component
            :for={entry <- @entries}
            module={LantternWeb.AssessmentPointEntryFormLiveComponent}
            id={entry.id}
            entry={entry}
            ordinal_value_options={@ordinal_value_options}
            scale={@assessment_point.scale}
          />
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    try do
      Assessments.get_assessment_point!(id, [
        :curriculum_item,
        :scale,
        :classes
      ])
    rescue
      _ ->
        socket =
          socket
          |> put_flash(:error, "Couldn't find assessment point")
          |> redirect(to: ~p"/assessment_points")

        {:noreply, socket}
    else
      assessment_point ->
        entries =
          Assessments.list_assessment_point_entries(
            preloads: :student,
            assessment_point_id: assessment_point.id
          )
          |> Enum.sort_by(& &1.student.name)

        ordinal_values =
          if assessment_point.scale.type == "ordinal" do
            Grading.list_ordinal_values_from_scale(assessment_point.scale.id)
          else
            nil
          end

        ordinal_value_options =
          if is_list(ordinal_values) do
            ordinal_values |> Enum.map(fn ov -> {:"#{ov.name}", ov.id} end)
          else
            []
          end

        formatted_datetime =
          Timex.format!(
            Timex.local(assessment_point.datetime),
            "{Mshort} {D}, {YYYY}, {h12}:{m} {am}"
          )

        socket =
          socket
          |> assign(:assessment_point, assessment_point)
          |> assign(:entries, entries)
          |> assign(:ordinal_values, ordinal_values)
          |> assign(:formatted_datetime, formatted_datetime)
          |> assign(:ordinal_value_options, ordinal_value_options)

        {:noreply, socket}
    end
  end

  attr :ordinal_values, :list, required: true

  def ordinal_values(assigns) do
    ~H"""
    <div :if={@ordinal_values} class="flex items-center gap-2 ml-2">
      <%= for ov <- @ordinal_values do %>
        <.badge>
          <%= ov.name %>
        </.badge>
      <% end %>
    </div>
    """
  end

  attr :classes, :list, required: true

  def classes(assigns) do
    ~H"""
    <div class="flex items-center gap-2 ml-2">
      <%= for c <- @classes do %>
        <.badge>
          <%= c.name %>
        </.badge>
      <% end %>
    </div>
    """
  end
end

defmodule LantternWeb.AssessmentPointEntryFormLiveComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Grading.Scale

  # attr :scale, Scale, required: true
  # attr :ordinal_value_options, :list
  # attr :entry, ast entry, required: true

  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} phx-change="save" class="flex items-stretch gap-2 mt-4" phx-target={@myself}>
        <input type="hidden" name={@form[:id].name} value={@form[:id].value} />
        <div class="self-center shrink-0 w-1/4 text-sm">Student <%= @entry.student.name %></div>
        <.marking_column scale={@scale} ordinal_value_options={@ordinal_value_options} form={@form} />
        <div class="flex-[2_0]">
          <.textarea
            name={@form[:observation].name}
            errors={@form[:observation].errors}
            phx-debounce="1000"
            value={@form[:observation].value}
          />
        </div>
      </.form>
    </div>
    """
  end

  def update(assigns, socket) do
    form =
      assigns.entry
      |> Assessments.change_assessment_point_entry()
      |> to_form()

    socket =
      socket
      |> assign(:form, form)
      |> assign(:entry, assigns.entry)
      |> assign(:scale, assigns.scale)
      |> assign(:ordinal_value_options, assigns.ordinal_value_options)

    {:ok, socket}
  end

  attr :scale, Scale, required: true
  attr :ordinal_value_options, :list
  attr :form, Phoenix.HTML.Form, required: true

  def marking_column(%{scale: %{type: "ordinal"}} = assigns) do
    ~H"""
    <div class="flex-[2_0]">
      <.select
        name={@form[:ordinal_value_id].name}
        prompt="—"
        options={@ordinal_value_options}
        value={@form[:ordinal_value_id].value}
        class="h-full text-center"
      />
    </div>
    """
  end

  # numeric scale
  def marking_column(assigns) do
    ~H"""
    <div class="flex-[1_0]">
      <.base_input
        name={@form[:score].name}
        errors={@form[:score].errors}
        type="number"
        phx-debounce="1000"
        value={@form[:score].value}
        class="h-full text-center"
        min={@scale.start}
        max={@scale.stop}
      />
    </div>
    """
  end

  def handle_event("save", %{"assessment_point_entry" => params}, socket) do
    case Assessments.update_assessment_point_entry(socket.assigns.entry, params,
           preloads: :student
         ) do
      {:ok, assessment_point_entry} ->
        socket =
          socket
          |> assign(:entry, assessment_point_entry)

        {:noreply, socket}

      {:error, %Ecto.Changeset{errors: [score: {score_error, _}]} = _changeset} ->
        socket =
          socket
          |> put_flash(:error, score_error)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Something is not right")

        {:noreply, socket}
    end
  end
end
