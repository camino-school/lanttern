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
            preloads: [:student, :ordinal_value],
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
          |> assign(:ordinal_value_options, ordinal_value_options)
          |> assign(:formatted_datetime, formatted_datetime)

        {:noreply, socket}
    end
  end

  def handle_info(
        {:save_error, %Ecto.Changeset{errors: [score: {score_error, _}]} = _changeset},
        socket
      ) do
    socket =
      socket
      |> put_flash(:error, score_error)

    {:noreply, socket}
  end

  def handle_info({:save_error, _changeset}, socket) do
    socket =
      socket
      |> put_flash(:error, "Something is not right")

    {:noreply, socket}
  end

  attr :ordinal_values, :list, required: true

  def ordinal_values(assigns) do
    ~H"""
    <div :if={@ordinal_values} class="flex items-center gap-2 ml-2">
      <%= for ov <- @ordinal_values do %>
        <.badge get_bagde_color_from={ov}>
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

# I know we shouldn't have 2 modules in the same file,
# but this live component is meant to be used in this live view only
# so I'll keep it here for now

# expected external assigns
# attr :scale, Scale, required: true
# attr :ordinal_value_options, :list
# attr :entry, :map, required: true
defmodule LantternWeb.AssessmentPointEntryFormLiveComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Grading.Scale

  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} phx-change="save" class="flex items-stretch gap-2 mt-4" phx-target={@myself}>
        <input type="hidden" name={@form[:id].name} value={@form[:id].value} />
        <div class="self-center shrink-0 w-1/4 text-sm">Student <%= @student_name %></div>
        <.marking_column
          scale={@scale}
          ordinal_value_options={@ordinal_value_options}
          form={@form}
          style={@ov_style}
          ov_name={@ov_name}
        />
        <div class="flex-[2_0]">
          <.textarea
            name="assessment_point_entry[observation]"
            phx-debounce="1000"
            value={@form[:observation].value}
            class={@form[:observation].value == nil && "bg-slate-200"}
          />
        </div>
      </.form>
    </div>
    """
  end

  def update(
        %{entry: entry, scale: scale, ordinal_value_options: ordinal_value_options} = _assigns,
        socket
      ) do
    {ov_style, ov_name} =
      case entry.ordinal_value do
        %{name: name} = ov ->
          {get_colors_style(ov), name}

        _ ->
          {nil, nil}
      end

    form =
      entry
      |> Assessments.change_assessment_point_entry(%{})
      |> to_form()

    socket =
      socket
      |> assign(:ov_style, ov_style)
      |> assign(:ov_name, ov_name)
      |> assign(:form, form)
      |> assign(:student_name, entry.student.name)
      |> assign(:scale, scale)
      |> assign(:ordinal_value_options, ordinal_value_options)

    {:ok, socket}
  end

  attr :scale, Scale, required: true
  attr :ordinal_value_options, :list
  attr :style, :string
  attr :ov_name, :string
  attr :form, :map, required: true

  def marking_column(%{scale: %{type: "ordinal"}} = assigns) do
    ~H"""
    <div class="relative flex-[2_0]">
      <div
        class={[
          "flex items-center justify-center w-full h-full rounded-sm font-mono text-sm pointer-events-none",
          @form[:ordinal_value_id].value == nil && "bg-slate-200"
        ]}
        style={@style}
      >
        <%= @ov_name || "—" %>
      </div>
      <.select
        name={@form[:ordinal_value_id].name}
        prompt="—"
        options={@ordinal_value_options}
        value={@form[:ordinal_value_id].value}
        class="absolute inset-0 text-center text-transparent"
        style="background-color: transparent"
      />
    </div>
    """
  end

  def marking_column(%{scale: %{type: "numeric"}} = assigns) do
    ~H"""
    <div class="flex-[1_0]">
      <.base_input
        name={@form[:score].name}
        type="number"
        phx-debounce="1000"
        value={@form[:score].value}
        errors={@form[:score].errors}
        class={[
          "h-full font-mono text-center",
          @form[:score].value == nil && "bg-slate-200"
        ]}
        min={@scale.start}
        max={@scale.stop}
      />
    </div>
    """
  end

  def handle_event("save", %{"assessment_point_entry" => params}, socket) do
    cur_entry = Assessments.get_assessment_point_entry!(params["id"])

    case Assessments.update_assessment_point_entry(cur_entry, params,
           preloads: [:student, :ordinal_value],
           force_preloads: true
         ) do
      {:ok, assessment_point_entry} ->
        {ov_style, ov_name} =
          case assessment_point_entry.ordinal_value do
            %{name: name} = ov ->
              {get_colors_style(ov), name}

            _ ->
              {nil, nil}
          end

        form =
          assessment_point_entry
          |> Assessments.change_assessment_point_entry(%{})
          |> to_form()

        socket =
          socket
          |> assign(:ov_style, ov_style)
          |> assign(:ov_name, ov_name)
          |> assign(:form, form)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        send(self(), {:save_error, changeset})
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp get_colors_style(%OrdinalValue{} = ordinal_value) do
    "background-color: #{ordinal_value.bg_color}; color: #{ordinal_value.text_color}"
  end

  defp get_colors_style(_), do: ""
end
