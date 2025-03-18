defmodule LantternWeb.ClassLive.ILPComponent do
  use LantternWeb, :live_component

  alias Lanttern.ILP
  alias Lanttern.Schools

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, save_profile_filters: 2]

  # shared components
  alias LantternWeb.ILP.StudentILPComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex justify-between gap-4 p-4">
        <%= if @has_templates do %>
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
        <% else %>
          <p>
            <%= gettext(
              "No ILP templates registered in your school. Talk to your Lanttern school manager."
            ) %>
          </p>
        <% end %>
        <div class="flex items-center gap-2">
          <%= gettext("%{count} of %{total} ILPs created", count: @ilps_count, total: @students_count) %>
          <div class="w-32 h-4 p-1 rounded-full bg-white overflow-hidden shadow-inner">
            <div
              class="h-full rounded-full bg-ltrn-primary"
              style={"width: #{(@ilps_count/@students_count) * 100}%"}
            />
          </div>
        </div>
      </.action_bar>
      <.responsive_container class="py-10 px-4">
        <%= if !@current_template do %>
          <.card_base class="p-10">
            <.empty_state><%= gettext("No ILP template selected") %></.empty_state>
          </.card_base>
        <% else %>
          <%= if @student do %>
            <.scroll_to_top id="ilp-details-scroll-to-top" />
            <.live_component
              module={StudentILPComponent}
              id={"#{@id}-student-ilp"}
              template={@current_template}
              student={@student}
              cycle={@current_user.current_profile.current_school_cycle}
              current_profile={@current_user.current_profile}
              params={@params}
              on_edit_patch={fn id -> "#{@base_path}?edit_student_ilp=#{id}" end}
              create_patch={"#{@base_path}?edit_student_ilp=new"}
              on_edit_cancel={JS.patch("#{@base_path}")}
              edit_navigate={"#{@base_path}"}
            />
          <% else %>
            <.scroll_to_top id="students-and-ilps-scroll-to-top" />
            <div id={"#{@id}-students-and-ilps"} phx-update="stream">
              <.card_base
                :for={{dom_id, {student, ilp}} <- @streams.students_and_ilps}
                class="flex items-center gap-4 p-4 mt-4"
                id={dom_id}
              >
                <.profile_picture_with_name
                  profile_name={student.name}
                  picture_url={student.profile_picture_url}
                  navigate={~p"/school/students/#{student}"}
                  picture_size="sm"
                  class="flex-1"
                />
                <%= if ilp do %>
                  <.action
                    type="link"
                    navigate={~p"/ilp?student=#{student.id}"}
                    theme="primary"
                    icon_name="hero-eye-mini"
                    target="_blank"
                  >
                    <%= gettext("View ILP") %>
                  </.action>
                  <div class="group relative shrink-0 flex items-center gap-1 pl-4">
                    <.toggle
                      enabled={not is_nil(ilp) and ilp.is_shared_with_student}
                      theme="student"
                      phx-click={%JS{}}
                    />
                    <.icon name="hero-user-mini" />
                    <.tooltip><%= gettext("Shared with student") %></.tooltip>
                  </div>
                  <div class="group relative shrink-0 flex items-center gap-1">
                    <.toggle
                      enabled={not is_nil(ilp) and ilp.is_shared_with_guardians}
                      theme="student"
                      phx-click={%JS{}}
                    />
                    <.icon name="hero-users-mini" />
                    <.tooltip><%= gettext("Shared with guardians") %></.tooltip>
                  </div>
                <% else %>
                  <.action
                    type="link"
                    patch={~p"/ilp?student=#{student.id}&edit_student_ilp=new"}
                    theme="subtle"
                    icon_name="hero-plus-circle-mini"
                    target="_blank"
                  >
                    <%= gettext("Create ILP") %>
                  </.action>
                <% end %>
              </.card_base>
            </div>
          <% end %>
        <% end %>
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
        :students_and_ilps,
        dom_id: fn {student, _ilp} -> "student-#{student.id}" end
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
      |> assign_student()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_user_filters([:ilp_template])
    |> assign_base_path()
    |> assign_templates()
    |> assign_current_template()
    |> stream_students_and_ilps()
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

  defp stream_students_and_ilps(%{assigns: %{selected_ilp_template_id: ilp_template_id}} = socket)
       when is_integer(ilp_template_id) do
    cycle_id = socket.assigns.current_user.current_profile.current_school_cycle.id
    school_id = socket.assigns.current_user.current_profile.school_id

    students_and_ilps =
      ILP.list_students_and_ilps(
        school_id,
        cycle_id,
        ilp_template_id,
        classes_ids: [socket.assigns.class.id]
      )

    students_count = length(students_and_ilps)

    ilps_count =
      students_and_ilps
      |> Enum.filter(fn {_student, ilp} -> ilp end)
      |> length()

    socket
    |> stream(:students_and_ilps, students_and_ilps)
    |> assign(:has_students_and_ilps, students_and_ilps != [])
    |> assign(
      :students_ids,
      Enum.map(students_and_ilps, fn {student, _ilp} -> "#{student.id}" end)
    )
    |> assign(:students_count, students_count)
    |> assign(:ilps_count, ilps_count)
  end

  defp stream_students_and_ilps(socket) do
    socket
    |> stream(:students_and_ilps, [])
    |> assign(:has_students_and_ilps, false)
    |> assign(:students_ids, [])
  end

  defp assign_student(%{assigns: %{params: %{"view_ilp_of_student" => id}}} = socket) do
    if id in socket.assigns.students_ids do
      student = Schools.get_student!(id)
      assign(socket, :student, student)
    else
      assign(socket, :student, nil)
    end
  end

  defp assign_student(socket), do: assign(socket, :student, nil)

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
