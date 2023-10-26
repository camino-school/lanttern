defmodule LantternWeb.CurriculumBNCCEFLive do
  use LantternWeb, :live_view

  alias Lanttern.BNCC

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <.page_title_with_menu>BNCC Ensino Fundamental</.page_title_with_menu>
      <div class="flex items-center mt-2 font-display font-bold text-xs text-ltrn-subtle">
        <.link navigate={~p"/curriculum"} class="underline">Curriculum</.link>
        <span class="mx-1">/</span>
        <span>BNCC EF</span>
      </div>
    </div>
    <div class="container mx-auto lg:max-w-5xl mt-10">
      <div class="flex items-center text-sm">
        <p class="flex items-center gap-2">
          <%= @items_count %> results in
          <%= if @current_subjects == [] do %>
            <.badge>all subjects</.badge>
          <% else %>
            <.badge :for={sub <- @current_subjects}>
              <%= sub.name %>
            </.badge>
          <% end %>
          <span>|</span>
          <%= if @current_years == [] do %>
            <.badge>all years</.badge>
          <% else %>
            <.badge :for={year <- @current_years}>
              <%= year.name %>
            </.badge>
          <% end %>
        </p>
        <button class="flex items-center ml-4 text-ltrn-subtle" phx-click={show_filter()}>
          <.icon name="hero-funnel-mini" class="text-ltrn-primary mr-2" />
          <span class="underline">Filter</span>
        </button>
      </div>
    </div>
    <div class="relative w-full mt-6 rounded shadow-xl bg-white">
      <%= if @items_count == 0 do %>
        No results
      <% else %>
        <.table id="habilidades-bncc" rows={@streams.habilidades_bncc}>
          <:col :let={{_id, ha}} label="ID">#<%= ha.id %></:col>
          <:col :let={{_id, ha}} label="Code"><%= ha.code %></:col>
          <:col :let={{_id, ha}} label="Campo de Atuação">
            <%= ha.campo_de_atuacao || "—" %>
          </:col>
          <:col :let={{_id, ha}} label="Prática de Linguagem">
            <%= ha.pratica_de_linguagem || "—" %>
          </:col>
          <:col :let={{_id, ha}} label="Unidade Temática">
            <%= ha.unidade_tematica || "—" %>
          </:col>
          <:col :let={{_id, ha}} label="Objeto de Conhecimento">
            <%= ha.objeto_de_conhecimento %>
          </:col>
          <:col :let={{_id, ha}} label="Habilidade"><%= ha.name %></:col>
        </.table>
      <% end %>
    </div>
    <.slide_over id="bncc-ef-filters">
      <:title>Filter Curriculum</:title>
      <.form id="bncc-ef-filters-form" for={@form} phx-submit={filter()} class="flex gap-6">
        <fieldset class="flex-1">
          <legend class="text-base font-semibold leading-6 text-ltrn-subtle">Subjects</legend>
          <div class="mt-4 divide-y divide-ltrn-lighter border-b border-t border-ltrn-lighter">
            <.check_field
              :for={opt <- @ef_subjects}
              id={"subject-#{opt.id}"}
              field={@form[:subjects_ids]}
              opt={opt}
            />
          </div>
        </fieldset>
        <fieldset class="flex-1">
          <legend class="text-base font-semibold leading-6 text-ltrn-subtle">Years</legend>
          <div class="mt-4 divide-y divide-ltrn-lighter border-b border-t border-ltrn-lighter">
            <.check_field
              :for={opt <- @ef_years}
              id={"year-#{opt.id}"}
              field={@form[:years_ids]}
              opt={opt}
            />
          </div>
        </fieldset>
      </.form>
      <:actions>
        <.button
          type="button"
          theme="ghost"
          phx-click={JS.exec("data-cancel", to: "#bncc-ef-filters")}
        >
          Cancel
        </.button>
        <.button type="submit" form="bncc-ef-filters-form" phx-disable-with="Applying filters...">
          Apply filters
        </.button>
      </:actions>
    </.slide_over>
    """
  end

  # lifecycle

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_params, _uri, socket) do
    current_subjects = []
    current_years = []
    habilidades_bncc = BNCC.list_bncc_ef_items()
    items_count = length(habilidades_bncc)

    form =
      %{
        "subjects_ids" => [],
        "years_ids" => []
      }
      |> Phoenix.Component.to_form()

    ef_subjects = BNCC.list_bncc_ef_subjects()
    ef_years = BNCC.list_bncc_ef_years()

    socket =
      socket
      |> stream(:habilidades_bncc, habilidades_bncc)
      |> assign(:current_subjects, current_subjects)
      |> assign(:current_years, current_years)
      |> assign(:items_count, items_count)
      |> assign(:form, form)
      |> assign(:ef_subjects, ef_subjects)
      |> assign(:ef_years, ef_years)

    {:noreply, socket}
  end

  # event handlers

  def handle_event("show-filter", _, socket) do
    subjects_ids =
      socket.assigns.current_subjects
      |> Enum.map(&"#{&1.id}")

    years_ids =
      socket.assigns.current_years
      |> Enum.map(&"#{&1.id}")

    form =
      %{
        "subjects_ids" => subjects_ids,
        "years_ids" => years_ids
      }
      |> Phoenix.Component.to_form()

    socket =
      socket
      |> assign(:form, form)

    {:noreply, socket}
  end

  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  def handle_event("filter", params, socket) do
    subjects_ids = Map.get(params, "subjects_ids")
    years_ids = Map.get(params, "years_ids")
    filters = [subjects_ids: subjects_ids, years_ids: years_ids]

    current_subjects =
      case subjects_ids do
        nil ->
          []

        ids ->
          socket.assigns.ef_subjects
          |> Enum.filter(&("#{&1.id}" in ids))
      end

    current_years =
      case years_ids do
        nil ->
          []

        ids ->
          socket.assigns.ef_years
          |> Enum.filter(&("#{&1.id}" in ids))
      end

    habilidades_bncc = BNCC.list_bncc_ef_items(filters: filters)
    items_count = length(habilidades_bncc)

    socket =
      socket
      |> stream(:habilidades_bncc, habilidades_bncc, reset: true)
      |> assign(:current_subjects, current_subjects)
      |> assign(:current_years, current_years)
      |> assign(:items_count, items_count)

    {:noreply, socket}
  end

  # helpers

  defp show_filter(js \\ %JS{}) do
    js
    |> JS.push("show-filter")
    |> JS.exec("data-show", to: "#bncc-ef-filters")
  end

  defp filter(js \\ %JS{}) do
    js
    |> JS.push("filter")
    |> JS.exec("data-cancel", to: "#bncc-ef-filters")
  end
end
