defmodule LantternWeb.BnccEfLive do
  use LantternWeb, :live_view

  alias Lanttern.BNCC

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

    habilidades_bncc = BNCC.list_bncc_ef_items(subjects_ids: subjects_ids, years_ids: years_ids)
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
