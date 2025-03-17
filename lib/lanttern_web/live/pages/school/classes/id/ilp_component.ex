defmodule LantternWeb.ClassLive.ILPComponent do
  use LantternWeb, :live_component

  alias Lanttern.ILP

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, save_profile_filters: 2]

  # shared components
  # alias LantternWeb.ILP.StudentILPComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="p-4">
        <%= if @has_templates do %>
          <div class="flex items-center gap-4">
            <div class="relative">
              <.action
                type="button"
                id="select-template-dropdown-button"
                icon_name="hero-chevron-down-mini"
              >
                <%= if @current_template do %>
                  <%= gettext("ILP model:") %>
                  <span class="font-bold"><%= @current_template.name %></span>
                <% else %>
                  <%= gettext("No ILP model selected") %>
                <% end %>
              </.action>
              <.dropdown_menu
                id="select-template-dropdown"
                button_id="select-template-dropdown-button"
                z_index="10"
              >
                <:item
                  :for={{template_id, template_name} <- @template_options}
                  text={template_name}
                  on_click={
                    JS.push("select_template_id", value: %{"id" => template_id}, target: @myself)
                  }
                />
              </.dropdown_menu>
            </div>
          </div>
        <% else %>
          <p>
            <%= gettext(
              "No ILP templates registered in your school. Talk to your Lanttern school manager."
            ) %>
          </p>
        <% end %>
      </.action_bar>
      <.responsive_container class="py-10 px-4">
        <div id={"#{@id}-classes-students-and-ilps"} phx-update="stream">
          <div
            :for={{dom_id, {class, students_and_ilps}} <- @streams.classes_students_and_ilps}
            class="mt-10"
            id={dom_id}
          >
            <div class="font-bold"><%= class.name %></div>
            <.card_base
              :for={{student, ilp} <- students_and_ilps}
              class="flex items-center gap-4 p-4 mt-4"
              id={"student-#{student.id}"}
            >
              <.profile_picture_with_name
                profile_name={student.name}
                picture_url={student.profile_picture_url}
                picture_size="sm"
                navigate={~p"/school/students/#{student}/ilp"}
                class="flex-1"
              />
              <%= if ilp do %>
                <div><%= gettext("View ILP") %></div>
              <% else %>
                <.empty_state_simple>
                  <%= gettext("No ILP created") %>
                </.empty_state_simple>
              <% end %>
              <div class="group relative shrink-0 flex items-center gap-1">
                <.icon name="hero-user-mini" />
                <.toggle enabled theme="student" phx-click={%JS{}} />
                <.tooltip><%= gettext("Shared with student") %></.tooltip>
              </div>
              <div class="group relative shrink-0 flex items-center gap-1">
                <.icon name="hero-users-mini" />
                <.toggle enabled={false} theme="student" phx-click={%JS{}} />
                <.tooltip><%= gettext("Shared with guardians") %></.tooltip>
              </div>
            </.card_base>
          </div>
        </div>
      </.responsive_container>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> stream_configure(
        :classes_students_and_ilps,
        dom_id: fn {class, _students_and_ilps} -> "class-#{class.id}" end
      )
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_user_filters([:ilp_template])
    |> assign_base_path()
    |> assign_templates()
    |> assign_current_template()
    |> stream_classes_students_and_ilps()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_base_path(socket) do
    base_path = ~p"/school/classes/#{socket.assigns.class}/ilp"
    assign(socket, :base_path, base_path)
  end

  defp assign_templates(socket) do
    templates =
      ILP.list_ilp_templates(school_id: socket.assigns.current_user.current_profile.school_id)

    socket
    |> assign(:has_templates, length(templates) > 0)
    |> assign(:templates_ids, Enum.map(templates, & &1.id))
    |> assign(:template_options, Enum.map(templates, &{&1.id, &1.name}))
  end

  # when user has no selected ilp_template,
  # select first item in templates list as default if possible
  defp assign_current_template(%{assigns: %{selected_ilp_template_id: nil}} = socket) do
    template =
      case socket.assigns.templates_ids do
        [] -> nil
        [id | _] -> ILP.get_ilp_template!(id, preloads: [sections: :components])
      end

    if template do
      socket
      |> assign(:current_template, template)
      |> assign(:selected_ilp_template_id, template.id)
      |> save_profile_filters([:ilp_template])
    else
      assign(socket, :current_template, nil)
    end
  end

  # when user has selected ilp_template, validate access before loading it
  # (in case the selected template is not valid, remove it from profile and refresh the page)
  defp assign_current_template(socket) do
    template_id = socket.assigns.selected_ilp_template_id

    template =
      if template_id in socket.assigns.templates_ids do
        ILP.get_ilp_template!(template_id, preloads: [sections: :components])
      end

    if template do
      assign(socket, :current_template, template)
    else
      socket
      |> assign(:selected_ilp_template_id, nil)
      |> save_profile_filters([:ilp_template])
      |> push_navigate(to: socket.assigns.base_path)
    end
  end

  defp stream_classes_students_and_ilps(
         %{assigns: %{selected_ilp_template_id: ilp_template_id}} = socket
       )
       when is_integer(ilp_template_id) do
    cycle_id = socket.assigns.current_user.current_profile.current_school_cycle.id
    school_id = socket.assigns.current_user.current_profile.school_id

    classes_students_and_ilps =
      ILP.list_students_and_ilps_grouped_by_class(
        school_id,
        cycle_id,
        ilp_template_id
      )

    socket
    |> stream(:classes_students_and_ilps, classes_students_and_ilps)
    |> assign(:has_classes_students_and_ilps, classes_students_and_ilps != [])
  end

  defp stream_classes_students_and_ilps(socket) do
    socket
    |> stream(:classes_students_and_ilps, [])
    |> assign(:has_classes_students_and_ilps, false)
  end

  # event handlers

  @impl true
  def handle_event("select_template_id", %{"id" => id}, socket) do
    template =
      if id in socket.assigns.templates_ids do
        ILP.get_ilp_template!(id, preloads: [sections: :components])
      end

    socket =
      socket
      |> assign(:current_template, template)
      |> assign(:selected_ilp_template_id, template && template.id)
      |> save_profile_filters([:ilp_template])
      |> push_navigate(to: socket.assigns.base_path)

    {:noreply, socket}
  end
end
