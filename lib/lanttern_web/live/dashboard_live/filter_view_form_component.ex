defmodule LantternWeb.DashboardLive.FilterViewFormComponent do
  @moduledoc """
  Profile view form component.

  This form is used inside a `<.slide_over>` component,
  where the "submit" button is rendered.
  """

  use LantternWeb, :live_component
  alias Lanttern.Personalization
  alias Lanttern.Personalization.ProfileView

  def render(assigns) do
    ~H"""
    <div>
      <.form
        id="assessment-points-filter-view-form"
        for={@form}
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
          Oops, something went wrong! Please check the errors below.
        </.error_block>
        <.input field={@form[:id]} type="hidden" />
        <.input field={@form[:profile_id]} type="hidden" />
        <.input field={@form[:name]} label="Filter view name" phx-debounce="1500" class="mb-6" />
        <div class="flex gap-6">
          <fieldset class="flex-1">
            <legend class="text-base font-semibold leading-6 text-ltrn-subtle">Classes</legend>
            <div class="mt-4 divide-y divide-ltrn-lighter border-b border-t border-ltrn-lighter">
              <.check_field
                :for={opt <- @classes}
                id={"class-#{opt.id}"}
                field={@form[:classes_ids]}
                opt={opt}
              />
            </div>
          </fieldset>
          <fieldset class="flex-1">
            <legend class="text-base font-semibold leading-6 text-ltrn-subtle">Subjects</legend>
            <div class="mt-4 divide-y divide-ltrn-lighter border-b border-t border-ltrn-lighter">
              <.check_field
                :for={opt <- @subjects}
                id={"subject-#{opt.id}"}
                field={@form[:subjects_ids]}
                opt={opt}
              />
            </div>
          </fieldset>
        </div>
      </.form>
    </div>
    """
  end

  # lifecycle

  def mount(socket) do
    classes = Lanttern.Schools.list_classes()
    subjects = Lanttern.Taxonomy.list_subjects()

    socket =
      socket
      |> assign(:classes, classes)
      |> assign(:subjects, subjects)
      |> assign(:action, "create")

    {:ok, socket}
  end

  def update(%{filter_view: filter_view} = assigns, socket) do
    changeset =
      filter_view
      |> Map.put(:classes_ids, Enum.map(filter_view.classes, &"#{&1.id}"))
      |> Map.put(:subjects_ids, Enum.map(filter_view.subjects, &"#{&1.id}"))
      |> Personalization.change_profile_view()

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(changeset))
      |> assign(:filter_view, filter_view)

    {:ok, socket}
  end

  def update(assigns, socket),
    do: {:ok, assign(socket, assigns)}

  # event handlers

  def handle_event("validate", %{"profile_view" => params}, socket) do
    form =
      %ProfileView{}
      |> Personalization.change_profile_view(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"profile_view" => params}, socket),
    do: save_filter_view(socket, socket.assigns.action, params)

  defp save_filter_view(socket, :new_filter_view, params) do
    case Personalization.create_profile_view(params) do
      {:ok, profile_view} ->
        notify_parent({:created, profile_view})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_filter_view(socket, :edit_filter_view, params) do
    # force classes_ids and subjects_ids inclusion to remove filters if needed
    params =
      params
      |> Map.put_new("classes_ids", [])
      |> Map.put_new("subjects_ids", [])

    case Personalization.update_profile_view(socket.assigns.filter_view, params) do
      {:ok, profile_view} ->
        notify_parent({:updated, profile_view})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
