defmodule LantternWeb.AssessmentsComponents do
  @moduledoc """
  Shared function components related to `Assessments` context
  """

  use Phoenix.Component

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.OverlayComponents

  alias Lanttern.Grading.OrdinalValue

  @doc """
  Renders an assessment point entry badge.
  """
  attr :entry, :any,
    required: true,
    doc: "Requires `scale` and `ordinal_value` preloads"

  attr :is_short, :boolean,
    default: false,
    doc: "Displays only the first 3 letters of the ordinal value"

  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def assessment_point_entry_badge(
        %{entry: %{ordinal_value: %OrdinalValue{}, scale: %{type: "ordinal"}}} = assigns
      ) do
    ov_name =
      if assigns.is_short do
        String.slice(assigns.entry.ordinal_value.name, 0..2)
      else
        assigns.entry.ordinal_value.name
      end

    assigns = assign(assigns, :ov_name, ov_name)

    ~H"""
    <.badge
      color_map={@entry.ordinal_value}
      class={@class}
      id={@id}
      title={if @is_short, do: @entry.ordinal_value.name}
    >
      <%= @ov_name %>
    </.badge>
    """
  end

  def assessment_point_entry_badge(%{entry: %{score: score, scale: %{type: "numeric"}}} = assigns)
      when not is_nil(score) do
    ~H"""
    <.badge class={@class} id={@id}>
      <%= @entry.score %>
    </.badge>
    """
  end

  def assessment_point_entry_badge(%{entry: nil} = assigns) do
    text =
      if assigns.is_short do
        "---"
      else
        gettext("No entry")
      end

    assigns = assign(assigns, :text, text)

    ~H"""
    <.badge class={@class} id={@id} theme="empty">
      <%= @text %>
    </.badge>
    """
  end

  def assessment_point_entry_badge(_assigns), do: nil

  @doc """
  Renders an assessment point entry display.
  """
  attr :entry, :any,
    required: true,
    doc: "Requires `scale`, `ordinal_value`, and `student_ordinal_value` preloads"

  attr :show_student_assessment, :boolean, default: false

  attr :prevent_preview, :boolean,
    default: false,
    doc: "use `true` to hide the final assessment from user"

  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def assessment_point_entry_display(%{prevent_preview: true} = assigns) do
    ~H"""
    <div class={["grid grid-cols-1 w-full", @class]} id={@id}>
      <div class={[
        assessment_point_entry_display_base_classes(),
        "border border-ltrn-light border-dashed text-ltrn-subtle"
      ]}>
        <%= gettext("Final assessment not available yet") %>
      </div>
    </div>
    """
  end

  def assessment_point_entry_display(assigns) do
    # even if show_student_assessment is true,
    # we need to check if there's actually some student assessment
    show_student_assessment =
      case {assigns.show_student_assessment, assigns.entry} do
        {true, %{scale_type: "ordinal", student_ordinal_value_id: ov_id}}
        when not is_nil(ov_id) ->
          true

        {true, %{scale_type: "numeric", student_score: score}} when not is_nil(score) ->
          true

        _ ->
          false
      end

    grid_cols_class = if show_student_assessment, do: "grid-cols-2", else: "grid-cols-1"

    assigns =
      assigns
      |> assign(:show_student_assessment, show_student_assessment)
      |> assign(:grid_cols_class, grid_cols_class)

    ~H"""
    <div class={["grid gap-1 w-full", @grid_cols_class, @class]} id={@id}>
      <.assessment_point_entry_value_display entry={@entry} />
      <.assessment_point_entry_value_display :if={@show_student_assessment} entry={@entry} is_student />
      <div :if={@show_student_assessment} class="text-xs text-center text-ltrn-teacher-dark">
        <%= gettext("Teacher assessment") %>
      </div>
      <div :if={@show_student_assessment} class="text-xs text-center text-ltrn-student-dark">
        <%= gettext("Student self-assessment") %>
      </div>
    </div>
    """
  end

  attr :entry, :any
  attr :is_student, :boolean, default: false

  defp assessment_point_entry_value_display(%{entry: %{scale_type: "ordinal"}} = assigns) do
    ov =
      if assigns.is_student,
        do: assigns.entry.student_ordinal_value,
        else: assigns.entry.ordinal_value

    assigns = assign(assigns, :ov, ov)

    ~H"""
    <%= if @ov do %>
      <div
        class={[assessment_point_entry_display_base_classes(), "shadow-lg"]}
        style={create_color_map_style(@ov)}
      >
        <%= @ov.name %>
      </div>
    <% else %>
      <.assessment_point_entry_value_empty_display />
    <% end %>
    """
  end

  defp assessment_point_entry_value_display(%{entry: %{scale_type: "numeric"}} = assigns) do
    score =
      if assigns.is_student,
        do: assigns.entry.student_score,
        else: assigns.entry.score

    assigns = assign(assigns, :score, score)

    ~H"""
    <%= if @score do %>
      <div class={[
        assessment_point_entry_display_base_classes(),
        "border border-ltrn-lighter bg-white shadow-lg"
      ]}>
        <%= @score %>
      </div>
    <% else %>
      <.assessment_point_entry_value_empty_display />
    <% end %>
    """
  end

  defp assessment_point_entry_value_display(assigns) do
    ~H"""
    <.assessment_point_entry_value_empty_display />
    """
  end

  defp assessment_point_entry_value_empty_display(assigns) do
    ~H"""
    <div class={[
      assessment_point_entry_display_base_classes(),
      "border border-dashed border-ltrn-light bg-ltrn-lighter"
    ]}>
      <%= gettext("No entry") %>
    </div>
    """
  end

  defp assessment_point_entry_display_base_classes(),
    do: "flex items-center justify-center p-4 rounded font-mono text-sm text-center"

  @doc """
  Renders a dropdown to control the assessment group by option.
  """
  attr :current_assessment_group_by, :string, required: true

  attr :on_change, :any,
    required: true,
    doc: "expects a function. Will pass `nil`, `\"curriculum\"`, or `\"moment\" as args"

  def assessment_group_by_dropdow(assigns) do
    text =
      case assigns.current_assessment_group_by do
        "curriculum" -> gettext("Show all, grouped by curriculum")
        "moment" -> gettext("Show all, grouped by moment")
        _ -> gettext("Show only goals assessments")
      end

    assigns = assign(assigns, :text, text)

    ~H"""
    <div class="relative">
      <.action type="button" id="group-by-dropdown-button" icon_name="hero-chevron-down-mini">
        <%= @text %>
      </.action>
      <.dropdown_menu id="group-by-dropdown" button_id="group-by-dropdown-button" z_index="30">
        <:item text={gettext("Show only goals assessments")} on_click={@on_change.(nil)} />
        <:item text={gettext("Show all, grouped by curriculum")} on_click={@on_change.("curriculum")} />
        <:item text={gettext("Show all, grouped by moment")} on_click={@on_change.("moment")} />
      </.dropdown_menu>
    </div>
    """
  end

  attr :current_assessment_view, :string, required: true

  attr :on_change, :any,
    required: true,
    doc: "expects a function. Will pass `\"teacher\"`, `\"student\"`, or `\"compare\" as args"

  def assessment_view_dropdow(assigns) do
    {theme, text} =
      case assigns.current_assessment_view do
        "teacher" -> {"teacher", gettext("Assessed by teacher")}
        "student" -> {"student", gettext("Assessed by students")}
        "compare" -> {"primary", gettext("Compare teacher/students")}
      end

    assigns =
      assigns
      |> assign(:theme, theme)
      |> assign(:text, text)

    ~H"""
    <div class="relative">
      <.action
        type="button"
        id="view-dropdown-button"
        icon_name="hero-chevron-down-mini"
        theme={@theme}
      >
        <%= @text %>
      </.action>
      <.dropdown_menu id="view-dropdown" button_id="view-dropdown-button" z_index="30">
        <:item text={gettext("Assessed by teacher")} on_click={@on_change.("teacher")} />
        <:item text={gettext("Assessed by students")} on_click={@on_change.("student")} />
        <:item
          text={gettext("Compare teacher and students assessments")}
          on_click={@on_change.("compare")}
        />
      </.dropdown_menu>
    </div>
    """
  end
end
