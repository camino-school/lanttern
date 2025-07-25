defmodule LantternWeb.ILP.StudentILPComponent do
  @moduledoc """
  Renders a `StudentILP`.

  ### Required attrs

  - `:student_ilp` - `StudentILP`
  - `:student` - `Student`. The student for the ILP
  - `:current_user` - `%User{}` in `socket.assigns.current_user`

  ### Optional attrs

  - `:template` - `ILPTemplate`. If provided by attr, the component will not fetch the template
  - `:show_actions` - boolean, if true, show the edit/share actions
  - `:edit_patch` - passed to edit action `patch` attr
  - `:is_ilp_manager` - boolean. If true, allow share management actions
  - `:show_teacher_notes` - boolean. If true, show teacher notes
  - `:class` - any, additional classes for the component

  """

  use LantternWeb, :live_component

  alias Lanttern.ILP
  alias Lanttern.ILP.ILPEntry
  alias Lanttern.ILP.StudentILP
  alias Lanttern.SupabaseHelpers

  # shared components
  import LantternWeb.ILPComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[card_base_classes(), "p-4 sm:p-6", @class]} id={@id}>
      <div class="flex items-center gap-4">
        <div class="flex-1 flex items-center gap-2">
          <h4 class="font-display font-black text-xl">
            <%= @template.name %> (<%= @student_ilp.cycle.name %>)
          </h4>
          <.action_icon
            :if={@template.description}
            type="button"
            name="hero-information-circle-mini"
            size="mini"
            sr_text={gettext("About this ILP model")}
            phx-click={JS.exec("data-show", to: "##{@id}-template-info-modal")}
          />
        </div>
        <.action
          :if={@show_actions && @edit_patch}
          type="link"
          icon_name="hero-pencil-mini"
          patch={@edit_patch}
        >
          <%= gettext("Edit") %>
        </.action>
        <.student_ilp_share_controls
          :if={@show_actions}
          id={"share-controls-#{@id}"}
          student_ilp={@student_ilp}
          show_controls={@is_ilp_manager}
          on_student_share_toggle={
            JS.push("toggle_shared",
              value: %{"is_shared_with_student" => !@student_ilp.is_shared_with_student},
              target: @myself
            )
          }
          on_guardians_share_toggle={
            JS.push("toggle_shared",
              value: %{"is_shared_with_guardians" => !@student_ilp.is_shared_with_guardians},
              target: @myself
            )
          }
        />
      </div>
      <div>
        <.card_base :for={section <- @template.sections} class="p-4 border border-ltrn-lightest mt-4">
          <div class="font-display font-black text-base">
            <%= section.name %>
          </div>
          <div :for={component <- section.components} class="p-4 rounded-sm mt-2 bg-ltrn-lightest">
            <div class="font-bold"><%= component.name %></div>
            <.ilp_entry entry={@component_entry_map[component.id]} class="mt-4" />
          </div>
        </.card_base>
      </div>
      <div :if={@student_ilp.notes} class="p-4 rounded-sm mt-6 bg-ltrn-mesh-cyan">
        <p class="flex items-center gap-2 font-bold mb-4">
          <.icon name="hero-pencil-square-mini" class="text-ltrn-primary" />
          <%= gettext("Notes") %>
        </p>
        <.markdown text={@student_ilp.notes} />
      </div>
      <div
        :if={@show_teacher_notes && @student_ilp.teacher_notes}
        class="p-4 rounded-sm mt-6 bg-ltrn-staff-lightest"
      >
        <p class="flex items-center gap-2 font-bold mb-4">
          <.icon name="hero-pencil-square-mini" class="text-ltrn-staff-accent" />
          <span class="text-ltrn-staff-dark"><%= gettext("Teacher notes (internal)") %></span>
        </p>
        <.markdown text={@student_ilp.teacher_notes} />
      </div>
      <.ilp_comments_list
        ilp_comments={@ilp_comments}
        current_profile={@current_user.current_profile}
        tz={@current_user.tz}
        class="mt-10"
        on_signed_url={&JS.push("signed_url", value: %{"url" => &1}, target: @myself)}
      />
      <.modal :if={@template.description} id={"#{@id}-template-info-modal"}>
        <h6 class="mb-6 font-display font-black text-xl">
          <%= gettext("About %{template}", template: @template.name) %>
        </h6>
        <.markdown text={@template.description} />
      </.modal>
    </div>
    """
  end

  # function components

  attr :entry, ILPEntry
  attr :class, :any, default: nil

  defp ilp_entry(%{entry: nil} = assigns) do
    ~H"""
    <.empty_state_simple class={@class}>
      <%= gettext("Nothing yet") %>
    </.empty_state_simple>
    """
  end

  defp ilp_entry(%{entry: %{description: nil}} = assigns) do
    ~H"""
    <.empty_state_simple class={@class}>
      <%= gettext("Nothing yet") %>
    </.empty_state_simple>
    """
  end

  defp ilp_entry(assigns) do
    ~H"""
    <.markdown text={@entry.description} class={["max-w-none", @class]} />
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:show_actions, false)
      |> assign(:on_edit_patch, nil)
      |> assign(:create_patch, nil)
      |> assign(:class, nil)
      |> assign(:show_teacher_notes, false)
      |> assign(:is_ilp_manager, false)
      |> assign(:template, nil)
      |> assign(:ilp_comments, [])
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
    |> assign_template()
    |> assign_component_entry_map()
    |> assign_ilp_comments()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_template(%{assigns: %{template: nil}} = socket) do
    template =
      ILP.get_ilp_template!(
        socket.assigns.student_ilp.template_id,
        preloads: [sections: :components]
      )

    assign(socket, :template, template)
  end

  defp assign_template(socket), do: socket

  defp assign_component_entry_map(socket) do
    student_ilp =
      if is_list(socket.assigns.student_ilp.entries) do
        socket.assigns.student_ilp
      else
        socket.assigns.student_ilp
        |> Lanttern.Repo.preload(:entries)
      end

    component_entry_map =
      socket.assigns.template.sections
      |> Enum.flat_map(& &1.components)
      |> Enum.map(fn component ->
        {
          component.id,
          Enum.find(student_ilp.entries, &(&1.component_id == component.id))
        }
      end)
      |> Enum.filter(fn {_component_id, entry} -> entry end)
      |> Enum.into(%{})

    socket
    |> assign(:student_ilp, student_ilp)
    |> assign(:component_entry_map, component_entry_map)
  end

  defp assign_ilp_comments(%{assigns: %{student_ilp: %StudentILP{id: id}}} = socket) do
    assign(socket, :ilp_comments, ILP.list_ilp_comments_by_student_ilp(id))
  end

  defp assign_ilp_comments(socket), do: socket

  # event handlers

  @impl true
  def handle_event("toggle_shared", params, socket) do
    ILP.update_student_ilp_sharing(
      socket.assigns.student_ilp,
      params,
      log_profile_id: socket.assigns.current_user.current_profile.id
    )
    |> case do
      {:ok, student_ilp} ->
        student_ilp = %{
          socket.assigns.student_ilp
          | is_shared_with_student: student_ilp.is_shared_with_student,
            is_shared_with_guardians: student_ilp.is_shared_with_guardians
        }

        socket =
          socket
          |> assign(:student_ilp, student_ilp)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("signed_url", %{"url" => url}, socket) do
    case SupabaseHelpers.create_signed_url(url) do
      {:ok, external} -> {:noreply, push_event(socket, "open_external", %{url: external})}
      {:error, :invalid_url} -> {:noreply, put_flash(socket, :error, gettext("Invalid URL"))}
    end
  end
end
