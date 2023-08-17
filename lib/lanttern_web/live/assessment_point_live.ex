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
        <div class="table w-full mt-20">
          <div class="table-header-group">
            <div class="table-row">
              <div class="table-cell"></div>
              <div class="table-cell">
                <div class="flex items-center p-2 font-display font-bold text-slate-400">
                  <.icon name="hero-view-columns" class="mr-4" /> Marking
                </div>
              </div>
              <div class="table-cell">
                <div class="flex items-center p-2 font-display font-bold text-slate-400">
                  <.icon name="hero-pencil-square" class="mr-4" /> Notes and observations
                </div>
              </div>
            </div>
          </div>
          <div class="table-row-group">
            <%= for f <- @entries_forms do %>
              <.level_row form={f} ordinal_value_options={@ordinal_value_options} />
            <% end %>
          </div>
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
        :classes,
        [entries: [:student]]
      ])
    rescue
      _ ->
        socket =
          socket
          |> put_flash(:error, "Couldn't find assessment point \"#{id}\"")
          |> redirect(to: ~p"/assessment_points")

        {:noreply, socket}
    else
      assessment_point ->
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

        entries_forms =
          assessment_point.entries
          |> Enum.map(fn entry ->
            entry
            |> Assessments.change_assessment_point_entry()
            |> to_form()
          end)

        socket =
          socket
          |> assign(:assessment_point, assessment_point)
          |> assign(:ordinal_values, ordinal_values)
          |> assign(:formatted_datetime, formatted_datetime)
          |> assign(:ordinal_value_options, ordinal_value_options)
          |> assign(:entries_forms, entries_forms)

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

  attr :ordinal_value_options, :list
  attr :form, Phoenix.HTML.Form, required: true

  def level_row(assigns) do
    ~H"""
    <.form for={@form} phx-change="save" class="table-row">
      <input type="hidden" name={@form[:id].name} value={@form[:id].value} />
      <div class="table-cell">Student <%= @form.data.student.name %></div>
      <div class="table-cell">
        <div class="p-2">
          <.select
            name={@form[:ordinal_value_id].name}
            prompt="—"
            options={@ordinal_value_options}
            value={@form[:ordinal_value_id].value}
          />
        </div>
      </div>
      <div class="table-cell">
        <div class="p-2">
          <textarea
            name={@form[:observation].name}
            class={[
              "block w-full min-h-[6rem] rounded-sm border-0 shadow-sm ring-1 ring-slate-200 sm:text-sm sm:leading-6",
              "focus:ring-2 focus:ring-cyan-400",
              "phx-no-feedback:ring-slate-200 phx-no-feedback:focus:ring-cyan-400",
              @form.errors != [] && "ring-rose-400 focus:ring-rose-400"
            ]}
            phx-debounce="1000"
          ><%= Phoenix.HTML.Form.normalize_value("textarea", @form[:observation].value) %></textarea>
        </div>
      </div>
    </.form>
    """
  end

  def handle_event("save", %{"assessment_point_entry" => params}, socket) do
    assessment_point_entry = Assessments.get_assessment_point_entry!(params["id"])

    case Assessments.update_assessment_point_entry(assessment_point_entry, params,
           preloads: :student
         ) do
      {:ok, assessment_point_entry} ->
        socket =
          socket
          |> update(:entries_forms, fn forms ->
            forms
            |> Enum.map(fn form ->
              if form.data.id == assessment_point_entry.id do
                assessment_point_entry
                |> Assessments.change_assessment_point_entry()
                |> to_form()
              else
                form
              end
            end)
          end)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Something is not right")

        {:noreply, socket}
    end
  end
end
