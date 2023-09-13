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
        <button class="flex items-center ml-4 text-ltrn-subtle" phx-click="show-filter">
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
            <%= if ha.campo_de_atuacao, do: ha.campo_de_atuacao.name, else: "—" %>
          </:col>
          <:col :let={{_id, ha}} label="Prática de Linguagem">
            <%= if ha.pratica_de_linguagem, do: ha.pratica_de_linguagem.name, else: "—" %>
          </:col>
          <:col :let={{_id, ha}} label="Unidade Temática">
            <%= if ha.unidade_tematica, do: ha.unidade_tematica.name, else: "—" %>
          </:col>
          <:col :let={{_id, ha}} label="Objeto de Conhecimento">
            <%= ha.objeto_de_conhecimento.name %>
          </:col>
          <:col :let={{_id, ha}} label="Habilidade"><%= ha.name %></:col>
        </.table>
      <% end %>
    </div>
    <.slide_over :if={@is_filtering} id="bncc-ef-filters">
      <:title>Filter Curriculum</:title>
      <.form id="bncc-ef-filters-form" for={@form} phx-submit="filter" class="flex gap-6">
        <fieldset class="flex-1">
          <legend class="text-base font-semibold leading-6 text-ltrn-subtle">Subjects</legend>
          <div class="mt-4 divide-y divide-ltrn-hairline border-b border-t border-ltrn-hairline">
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
          <div class="mt-4 divide-y divide-ltrn-hairline border-b border-t border-ltrn-hairline">
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
        <.button type="button" theme="ghost" phx-click="hide-filter">
          Cancel
        </.button>
        <.button type="submit" form="bncc-ef-filters-form" phx-disable-with="Applying filters...">
          Apply filters
        </.button>
      </:actions>
    </.slide_over>
    """
  end

  # function components

  attr :id, :string, required: true

  attr :opt, :map,
    required: true,
    doc: "Instance of `Lanttern.Taxonomy.Subject` or `Lanttern.Taxonomy.Year`"

  attr :field, Phoenix.HTML.FormField, required: true

  def check_field(assigns) do
    ~H"""
    <div class="relative flex items-start py-4">
      <div class="min-w-0 flex-1 text-sm leading-6">
        <label for={@id} class="select-none text-ltrn-text">
          <%= @opt.name %>
        </label>
      </div>
      <div class="ml-3 flex h-6 items-center">
        <input
          id={@id}
          name={@field.name <> "[]"}
          type="checkbox"
          value={@opt.id}
          class="h-4 w-4 rounded border-ltrn-subtle text-ltrn-primary focus:ring-ltrn-primary"
          checked={"#{@opt.id}" in @field.value}
        />
      </div>
    </div>
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
      |> assign(:is_filtering, false)
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
      |> assign(:is_filtering, true)

    {:noreply, socket}
  end

  def handle_event("hide-filter", _, socket) do
    {:noreply, assign(socket, :is_filtering, false)}
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
      |> assign(:is_filtering, false)

    {:noreply, socket}
  end
end
