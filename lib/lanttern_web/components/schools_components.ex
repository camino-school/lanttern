defmodule LantternWeb.SchoolsComponents do
  @moduledoc """
  Shared function components related to `Schools` context
  """

  use Phoenix.Component

  import Phoenix.HTML, only: [raw: 1]
  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.DateTimeHelpers
  alias Lanttern.Schools.School
  alias Lanttern.Schools.Student

  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  @doc """
  Renders a school branding footer.
  """

  attr :school, School, required: true
  attr :class, :any, default: nil

  def school_branding_footer(%{school: school} = assigns) do
    logo_image_url =
      case school.logo_image_url do
        nil ->
          nil

        url ->
          object_url_to_render_url(
            url,
            width: 128,
            height: 128
          )
      end

    assigns =
      assigns
      |> assign(:logo_image_url, logo_image_url)

    ~H"""
    <div
      class={["py-10 sm:py-20 bg-ltrn-dark", @class]}
      style={if @school.bg_color, do: "background-color: #{@school.bg_color}"}
    >
      <.responsive_container class="flex items-center gap-6 sm:gap-10">
        <div
          :if={@logo_image_url}
          class="shrink-0 w-32 h-32 rounded-full bg-white bg-cover bg-center shadow-lg"
          style={"background-image: url('#{@logo_image_url}')"}
        >
          <span class="sr-only">{gettext("School logo")}</span>
        </div>
        <div
          class="flex-1 text-white"
          style={if @school.text_color, do: "color: #{@school.text_color}"}
        >
          <p>
            {gettext(
              "Students information and learning data by %{school_name}.",
              school_name: "<strong>#{@school.name}</strong>"
            )
            |> raw()}
          </p>
          <p class="mt-4">
            {gettext(
              "Powered by %{lanttern}.",
              lanttern: "<strong>Lanttern</strong>"
            )
            |> raw()}
          </p>
        </div>
      </.responsive_container>
    </div>
    """
  end

  @doc """
  Renders a student card.
  """

  attr :student, Student, required: true
  attr :navigate, :string, default: nil, doc: "On name click"
  attr :show_edit, :boolean, default: false
  attr :edit_patch, :string, default: nil
  attr :class, :any, default: nil
  attr :id, :string, default: nil

  def student_card(assigns) do
    age = calculate_age(assigns.student.birthdate)

    has_badge =
      age != nil ||
        (is_list(assigns.student.classes) && assigns.student.classes != []) ||
        (is_list(assigns.student.tags) && assigns.student.tags != [])

    assigns =
      assigns
      |> assign(:has_badge, has_badge)
      |> assign(:age, age)

    ~H"""
    <.card_base id={@id} class={["flex items-center gap-4 p-4", @class]}>
      <.profile_picture
        picture_url={@student.profile_picture_url}
        profile_name={@student.name}
        size="lg"
      />
      <div class="min-w-0 flex-1">
        <%= if @navigate do %>
          <.link navigate={@navigate} class="font-bold hover:text-ltrn-subtle">
            {@student.name}
          </.link>
        <% else %>
          <div class="font-bold">
            {@student.name}
          </div>
        <% end %>
        <div :if={@has_badge} class="flex flex-wrap gap-1 mt-2">
          <%= if @age do %>
            <div class="group relative" tabindex="0">
              <.badge theme="dark">
                {format_age_short(@age)}
              </.badge>
              <.tooltip v_pos="top">
                {format_birthdate(@student.birthdate)}
              </.tooltip>
            </div>
          <% end %>
          <%= if is_list(@student.tags) do %>
            <.badge :for={tag <- @student.tags} color_map={tag}>
              {tag.name}
            </.badge>
          <% end %>
          <%= if is_list(@student.classes) do %>
            <.badge :for={class <- @student.classes}>
              {class.name}
            </.badge>
          <% end %>
        </div>
        <div
          :if={@student.email}
          class="mt-2 text-xs text-ltrn-subtle truncate"
          title={@student.email}
        >
          {@student.email}
        </div>
      </div>
      <.button
        :if={@show_edit}
        type="link"
        icon_name="hero-pencil-mini"
        sr_text={gettext("Edit student")}
        rounded
        size="sm"
        theme="ghost"
        patch={@edit_patch}
      />
    </.card_base>
    """
  end

  @doc """
  Renders a deactivated student card.
  """

  attr :student, Student, required: true
  attr :navigate, :string, default: nil, doc: "On name click"
  attr :show_actions, :boolean, default: false
  attr :on_reactivate, JS, default: nil
  attr :on_delete, JS, default: nil
  attr :class, :any, default: nil
  attr :id, :string, default: nil

  def deactivated_student_card(assigns) do
    ~H"""
    <.card_base id={@id} class="flex items-center gap-4 p-4">
      <.profile_picture
        picture_url={@student.profile_picture_url}
        profile_name={@student.name}
        size="lg"
      />
      <div class="min-w-0 flex-1">
        <div class="text-ltrn-subtle">
          <%= if @navigate do %>
            <.link navigate={@navigate} class="font-bold hover:text-ltrn-dark">
              {@student.name}
            </.link>
          <% else %>
            <div class="font-bold">
              {@student.name}
            </div>
          <% end %>
          <div
            :if={is_list(@student.classes) && @student.classes != []}
            class="flex flex-wrap gap-1 mt-2"
          >
            <.badge :for={class <- @student.classes}>{class.name}</.badge>
          </div>
          <div :if={@student.email} class="mt-2 text-xs truncate" title={@student.email}>
            {@student.email}
          </div>
        </div>
        <div :if={@show_actions} class="flex gap-4 mt-4">
          <.action type="button" phx-click={@on_reactivate}>
            {gettext("Reactivate")}
          </.action>
          <.action
            type="button"
            theme="alert"
            phx-click={@on_delete}
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
          </.action>
        </div>
      </div>
    </.card_base>
    """
  end

  @doc """
  Renders a staff member card (simple view for class page).
  """

  attr :staff_member, :map, required: true
  attr :navigate, :string, default: nil, doc: "On name click"
  attr :class_role, :string, default: nil
  attr :class, :any, default: nil
  attr :id, :string, default: nil

  def staff_member_simple_card(assigns) do
    ~H"""
    <.card_base id={@id} class={["flex items-center gap-4 p-4", @class]}>
      <.profile_picture
        picture_url={@staff_member.profile_picture_url}
        profile_name={@staff_member.name}
        size="lg"
      />
      <div class="min-w-0 flex-1">
        <%= if @navigate do %>
          <.link navigate={@navigate} class="font-bold hover:text-ltrn-subtle">
            {@staff_member.name}
          </.link>
        <% else %>
          <div class="font-bold">
            {@staff_member.name}
          </div>
        <% end %>
        <div class="text-xs text-ltrn-subtle">{@staff_member.role}</div>
        <div :if={@class_role} class="flex flex-wrap gap-1 mt-2">
          <.badge>{@class_role}</.badge>
        </div>
        <div
          :if={@staff_member.email}
          class="mt-2 text-xs text-ltrn-subtle truncate"
          title={@staff_member.email}
        >
          {@staff_member.email}
        </div>
      </div>
    </.card_base>
    """
  end

  @doc """
  Renders a class card for staff member management.
  """

  attr :class_staff_member, :map, required: true
  attr :show_actions, :boolean, default: false
  attr :on_edit_role, JS, default: nil
  attr :on_remove, JS, default: nil
  attr :sortable, :boolean, default: false
  attr :class, :any, default: nil
  attr :id, :string, default: nil
  attr :"data-id", :string, default: nil

  def class_card_for_staff(assigns) do
    ~H"""
    <.card_base id={@id} class={["flex items-center gap-4 p-4", @class]}>
      <.icon
        :if={@sortable}
        name="hero-bars-3"
        class="drag-handle cursor-grab text-ltrn-subtle hover:text-ltrn-dark"
      />
      <div class="min-w-0 flex-1">
        <div class="font-bold">
          {@class_staff_member.class.name} ({@class_staff_member.class.cycle.name})
        </div>
        <div class="text-xs text-ltrn-subtle">{@class_staff_member.class.school.name}</div>
        <div :if={@class_staff_member.role} class="flex flex-wrap gap-1 mt-2">
          <.badge>{@class_staff_member.role}</.badge>
        </div>
      </div>
      <div :if={@show_actions} class="flex gap-2">
        <.button
          type="button"
          icon_name="hero-pencil-mini"
          sr_text={gettext("Edit role")}
          rounded
          size="sm"
          theme="ghost"
          phx-click={@on_edit_role}
        />
        <.button
          type="button"
          icon_name="hero-x-mark-mini"
          sr_text={gettext("Remove from class")}
          rounded
          size="sm"
          theme="ghost"
          phx-click={@on_remove}
        />
      </div>
    </.card_base>
    """
  end
end
