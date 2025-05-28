defmodule LantternWeb.StudentLive.ILPComponent do
  use LantternWeb, :live_component

  alias Lanttern.ILP

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, save_profile_filters: 2]

  # shared components
  alias LantternWeb.ILP.StudentILPManagerComponent

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
        <.live_component
          module={StudentILPManagerComponent}
          id="student-ilp"
          template={@current_template}
          student={@student}
          cycle={@current_user.current_profile.current_school_cycle}
          current_profile={@current_user.current_profile}
          tz={@current_user.tz}
          is_ilp_manager={"ilp_management" in @current_user.current_profile.permissions}
          params={@params}
          on_edit_patch={fn _id -> "#{@base_path}?student_ilp=edit" end}
          create_patch={"#{@base_path}?student_ilp=new"}
          on_edit_cancel={JS.patch("#{@base_path}")}
          edit_navigate={"#{@base_path}"}
        />
      </.responsive_container>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
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
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_base_path(socket) do
    base_path = ~p"/school/students/#{socket.assigns.student}/ilp"
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
