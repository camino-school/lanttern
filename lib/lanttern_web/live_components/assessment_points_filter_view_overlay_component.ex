defmodule LantternWeb.AssessmentPointsFilterViewOverlayComponent do
  @moduledoc """
  ### PubSub: expected broadcast messages

  All messages should be broadcast to topic in assigns, following `{:key, msg}` pattern.

      - `:assessment_points_filter_view_created`

  ### Expected external assigns:

      attr :id, :string, required: true
      attr :current_user, User, required: true
      attr :show, :boolean, required: true
      attr :on_cancel, JS, default: %JS{}
      attr :filter_view_id, :integer, doc: "For updating views"
      attr :topic, :string
  """

  use LantternWeb, :live_component
  alias Phoenix.PubSub
  alias Lanttern.Explorer
  alias Lanttern.Explorer.AssessmentPointsFilterView

  def render(assigns) do
    ~H"""
    <div>
      <.slide_over :if={@show} id={@id} show={true} on_cancel={Map.get(assigns, :on_cancel, %JS{})}>
        <:title>
          <%= if @action == "create", do: "Create", else: "Update" %> assessment points filter view
        </:title>
        <.form
          id="assessment-points-filter-view-form"
          for={@form}
          phx-change="validate"
          phx-submit={@action}
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
              <div class="mt-4 divide-y divide-ltrn-hairline border-b border-t border-ltrn-hairline">
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
              <div class="mt-4 divide-y divide-ltrn-hairline border-b border-t border-ltrn-hairline">
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
        <:actions>
          <.button type="button" theme="ghost" phx-click={JS.exec("data-cancel", to: "##{@id}")}>
            Cancel
          </.button>
          <.button
            type="submit"
            form="assessment-points-filter-view-form"
            phx-disable-with="Saving..."
          >
            Save
          </.button>
        </:actions>
      </.slide_over>
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

  def update(%{show: true, filter_view_id: id} = assigns, socket) when is_integer(id) do
    filter_view = Explorer.get_assessment_points_filter_view!(id, preloads: [:classes, :subjects])

    changeset =
      filter_view
      |> Map.put(:classes_ids, Enum.map(filter_view.classes, &"#{&1.id}"))
      |> Map.put(:subjects_ids, Enum.map(filter_view.subjects, &"#{&1.id}"))
      |> Explorer.change_assessment_points_filter_view()

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(changeset))
      |> assign(:action, "update")
      |> assign(:filter_view, filter_view)

    {:ok, socket}
  end

  def update(%{show: true} = assigns, socket) do
    changeset =
      %AssessmentPointsFilterView{profile_id: assigns.current_user.current_profile.id}
      |> Explorer.change_assessment_points_filter_view()

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(changeset))
      |> assign(:action, "create")

    {:ok, socket}
  end

  def update(assigns, socket),
    do: {:ok, assign(socket, assigns)}

  # event handlers

  def handle_event("validate", %{"assessment_points_filter_view" => params}, socket) do
    form =
      %AssessmentPointsFilterView{}
      |> Explorer.change_assessment_points_filter_view(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("create", %{"assessment_points_filter_view" => params}, socket) do
    case Explorer.create_assessment_points_filter_view(params) do
      {:ok, assessment_points_filter_view} ->
        msg = {:assessment_points_filter_view_created, assessment_points_filter_view}

        if socket.assigns.topic do
          PubSub.broadcast(Lanttern.PubSub, socket.assigns.topic, msg)
        end

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("update", %{"assessment_points_filter_view" => params}, socket) do
    # force classes_ids and subjects_ids inclusion to remove filters if needed
    params =
      params
      |> Map.put_new("classes_ids", [])
      |> Map.put_new("subjects_ids", [])

    case Explorer.update_assessment_points_filter_view(socket.assigns.filter_view, params) do
      {:ok, assessment_points_filter_view} ->
        msg = {:assessment_points_filter_view_updated, assessment_points_filter_view}

        if socket.assigns.topic do
          PubSub.broadcast(Lanttern.PubSub, socket.assigns.topic, msg)
        end

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
