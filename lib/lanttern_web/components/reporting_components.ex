defmodule LantternWeb.ReportingComponents do
  @moduledoc """
  Shared function components related to `Reporting` context
  """

  use Phoenix.Component

  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents

  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]
  import Lanttern.Utils, only: [format_float: 1, format_normalized: 1]

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Grading.Scale
  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Schools.Cycle
  alias Lanttern.Taxonomy.Year

  # shared components
  alias LantternWeb.Assessments.EntryParticleComponent
  alias LantternWeb.Rubrics.RubricDescriptorsComponent
  import LantternWeb.AssessmentsComponents
  import LantternWeb.AttachmentsComponents
  import LantternWeb.GradingComponents, only: [ov_short: 1]

  @doc """
  Renders a strand report assessment point card with student entry display.

  When the assessment point `uses_composition`, the `particle_entries` (its component
  assessment points' student entries) are rendered as particles. The assessment point's own
  marking is masked when it is `is_hidden` (a hidden composed assessment point still renders,
  showing its composition, with its own marking hidden).
  """

  attr :id, :string, required: true
  attr :assessment_point, :map, required: true
  attr :patch, :string, required: true

  attr :particle_entries, :list,
    default: [],
    doc: "component assessment points' student entries, rendered as particles for composed APs"

  attr :class, :any, default: nil

  def strand_report_assessment_point_card(assigns) do
    ap = assigns.assessment_point
    entry = ap.student_entry
    flags = entry_card_flags(entry)

    is_diff = ap.is_differentiation
    has_rubric = !!ap.rubric_id
    has_info = !!ap.report_info

    has_icon =
      Enum.any?([
        is_diff,
        flags.has_diff_rubric,
        has_rubric,
        flags.has_teacher_comment,
        flags.has_student_comment,
        flags.has_evidences,
        has_info
      ])

    has_particles = ap.uses_composition and assigns.particle_entries != []

    assigns =
      assigns
      |> assign(:entry, entry)
      |> assign(:is_diff, is_diff)
      |> assign(:has_diff_rubric, flags.has_diff_rubric)
      |> assign(:has_rubric, has_rubric)
      |> assign(:has_teacher_comment, flags.has_teacher_comment)
      |> assign(:has_student_comment, flags.has_student_comment)
      |> assign(:has_evidences, flags.has_evidences)
      |> assign(:has_info, has_info)
      |> assign(:has_icon, has_icon)
      |> assign(:has_particles, has_particles)
      |> assign(:render_extra_fields, has_icon or has_particles)

    ~H"""
    <.link
      id={@id}
      patch={@patch}
      class={[
        "group/card block",
        "sm:grid sm:grid-cols-[minmax(10px,_3fr)_minmax(10px,_2fr)]",
        @class
      ]}
    >
      <.card_base class={[
        "p-4 group-hover/card:bg-ltrn-lightest",
        "sm:col-span-2 sm:grid sm:grid-cols-subgrid sm:items-center sm:gap-4"
      ]}>
        <div>
          <p class="font-bold text-ltrn-darkest">
            {@assessment_point.name}
          </p>
          <.markdown
            :if={@assessment_point.report_info}
            text={@assessment_point.report_info}
            class="mt-2 line-clamp-2"
          />
          <div
            :if={@render_extra_fields}
            class="shrink-0 flex items-center gap-4 max-w-full mt-2"
          >
            <div :if={@has_icon} class="flex items-center gap-1 text-ltrn-subtle">
              <p
                :if={@is_diff || @has_diff_rubric}
                class="font-sans font-bold text-sm text-ltrn-diff-dark"
              >
                {gettext("Diff")}
              </p>
              <.icon :if={@has_rubric || @has_diff_rubric} name="hero-view-columns-mini" />
              <.icon
                :if={@has_teacher_comment}
                name="hero-chat-bubble-oval-left-mini"
                class="text-ltrn-staff-accent"
              />
              <.icon
                :if={@has_student_comment}
                name="hero-chat-bubble-oval-left-mini"
                class="text-ltrn-student-accent"
              />
              <.icon :if={@has_evidences} name="hero-paper-clip-mini" />
              <.icon :if={@has_info} name="hero-information-circle-mini" />
            </div>
            <div :if={@has_particles} class="flex-1 flex flex-wrap gap-1">
              <.live_component
                :for={particle_entry <- @particle_entries}
                module={EntryParticleComponent}
                id={"#{@id}-particle-#{particle_entry.id}"}
                entry={particle_entry}
              />
            </div>
          </div>
        </div>
        <.assessment_point_entry_display
          entry={@entry}
          scale={@assessment_point.scale}
          show_student_assessment
          prevent_preview={@assessment_point.is_hidden}
          class="mt-4 sm:mt-0"
        />
      </.card_base>
    </.link>
    """
  end

  defp entry_card_flags(nil),
    do: %{
      has_diff_rubric: false,
      has_teacher_comment: false,
      has_student_comment: false,
      has_evidences: false
    }

  defp entry_card_flags(entry),
    do: %{
      has_diff_rubric: !!entry.differentiation_rubric_id,
      has_teacher_comment: !!entry.report_note,
      has_student_comment: !!entry.student_report_note,
      has_evidences: !!entry.has_evidences
    }

  @doc """
  Renders a teacher or student comment area
  """

  attr :comment, :string, required: true
  attr :type, :string, default: "teacher", doc: "teacher | student"
  attr :class, :any, default: nil

  def comment_area(assigns) do
    {bg_class, icon_class, text_class, text} =
      case assigns.type do
        "teacher" ->
          {"bg-ltrn-staff-lightest", "text-ltrn-staff-accent", "text-ltrn-staff-dark",
           gettext("Teacher comment")}

        "student" ->
          {"bg-ltrn-student-lightest", "text-ltrn-student-accent", "text-ltrn-student-dark",
           gettext("Student comment")}
      end

    assigns =
      assigns
      |> assign(:bg_class, bg_class)
      |> assign(:icon_class, icon_class)
      |> assign(:text_class, text_class)
      |> assign(:text, text)

    ~H"""
    <div class={["p-4 rounded-sm", @bg_class, @class]}>
      <div class="flex items-center gap-2 font-bold text-sm">
        <.icon name="hero-chat-bubble-oval-left" class={["w-6 h-6", @icon_class]} />
        <span class={@text_class}>{@text}</span>
      </div>
      <.markdown text={@comment} class="max-w-none mt-4" />
    </div>
    """
  end

  @doc """
  Renders a rubric area
  """

  attr :rubric, Rubric, required: true
  attr :entry, AssessmentPointEntry, default: nil
  attr :id, :string, required: true
  attr :class, :any, default: nil

  def rubric_area(assigns) do
    ~H"""
    <.card_base class={["p-2", @class]} id={@id}>
      <div class="flex items-center gap-2 mb-6">
        <div class="flex-1 pr-2">
          <.badge :if={@rubric.is_differentiation} theme="diff" class="mb-2">
            {gettext("Rubric differentiation")}
          </.badge>
          <p class="font-display font-black">
            {gettext("Rubric criteria")}: {@rubric.criteria}
          </p>
        </div>
      </div>
      <.live_component
        module={RubricDescriptorsComponent}
        id={"#{@id}-rubric-descriptors"}
        rubric={@rubric}
        highlight_level_for_entry={@entry}
        class="overflow-x-auto"
      />
    </.card_base>
    """
  end

  @doc """
  Renders a report card card (yes, card card, 2x).
  """
  attr :report_card, ReportCard, required: true
  attr :cycle, Cycle, default: nil
  attr :year, Year, default: nil
  attr :is_wip, :boolean, default: false
  attr :navigate, :string, default: nil

  attr :open_in_new, :string,
    default: nil,
    doc: "will render `<a>` tag with `target='_blank'` instead of `<.link>`"

  attr :hide_description, :boolean, default: false
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def report_card_card(assigns) do
    cover_image_url =
      assigns.report_card.cover_image_url
      |> object_url_to_render_url(width: 400, height: 200)

    assigns =
      assign(assigns, :cover_image_url, cover_image_url)

    ~H"""
    <div
      class={[
        "flex flex-col rounded-sm shadow-xl bg-white overflow-hidden",
        @class
      ]}
      id={@id}
    >
      <div
        class="relative w-full h-40 bg-center bg-cover"
        style={"background-image: url('#{@cover_image_url || "/images/cover-placeholder-sm.jpg"}')"}
      />
      <div class="flex-1 flex flex-col gap-6 p-6">
        <h5 class={[
          "font-display font-black text-xl line-clamp-3",
          "md:text-2xl md:leading-tight"
        ]}>
          <.link :if={@navigate} navigate={@navigate} class="hover:text-ltrn-subtle">
            {@report_card.name}
          </.link>
          <a :if={@open_in_new} href={@open_in_new} target="_blank" class="hover:text-ltrn-subtle">
            {@report_card.name}
          </a>
          <span :if={!@navigate && !@open_in_new} class={if @is_wip, do: "text-ltrn-subtle"}>
            {@report_card.name}
          </span>
        </h5>
        <div :if={@cycle || @year} class="flex flex-wrap gap-2">
          <.badge :if={@cycle}>
            {gettext("Cycle")}: {@cycle.name}
          </.badge>
          <.badge :if={@year}>
            {@year.name}
          </.badge>
        </div>
        <div :if={!@hide_description && @report_card.description} class="line-clamp-3">
          <.markdown text={@report_card.description} />
        </div>
      </div>
      <div :if={@is_wip} class="flex items-center gap-2 p-4 text-sm text-ltrn-subtle bg-ltrn-lightest">
        <.icon name="hero-lock-closed-mini" /> {gettext("Under development")}
      </div>
    </div>
    """
  end

  @doc """
  Renders a scale.
  """
  attr :scale, Scale, required: true, doc: "Requires `ordinal_values` preload"
  attr :rubric, Rubric, default: nil, doc: "Requires `descriptors` preload"
  attr :entry, AssessmentPointEntry, default: nil
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def report_scale(%{scale: %{type: "ordinal"}, rubric: %Rubric{} = rubric} = assigns) do
    n = length(rubric.descriptors)

    grid_template_columns_style =
      "grid-template-columns: repeat(#{n}, minmax(200px, 1fr))"

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)

    ~H"""
    <div class={["grid gap-1 min-w-full", @class]} id={@id} style={@grid_template_columns_style}>
      <.report_scale_descriptor
        :for={descriptor <- @rubric.descriptors}
        entry={@entry}
        ordinal_value={descriptor.ordinal_value}
        descriptor={descriptor}
      />
    </div>
    """
  end

  def report_scale(%{scale: %{type: "ordinal"}} = assigns) do
    ~H"""
    <.report_scale_ordinal_columns
      id={@id}
      class={@class}
      scale={@scale}
      rubric={@rubric}
      entry={@entry}
    />
    """
  end

  def report_scale(%{scale: %{type: "numeric"}} = assigns) do
    ~H"""
    <.report_scale_numeric_bar
      id={@id}
      class={["min-w-full", @class]}
      scale={@scale}
      score={@entry && @entry.score}
    />
    """
  end

  @doc """
  Renders an ordinal scale as a row of value columns, highlighting the entry's value.

  When a `rubric` is given, its descriptors are rendered below the matching values.
  """
  attr :scale, Scale, required: true, doc: "Requires `ordinal_values` preload"
  attr :rubric, Rubric, default: nil, doc: "Requires `descriptors` preload"
  attr :entry, AssessmentPointEntry, default: nil
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def report_scale_ordinal_columns(assigns) do
    %{ordinal_values: ordinal_values} = assigns.scale
    n = length(ordinal_values)

    grid_template_columns_style =
      if assigns.rubric,
        do: "grid-template-columns: repeat(#{n}, minmax(200px, 1fr))",
        else: "grid-template-columns: repeat(#{n}, minmax(min-content, 1fr))"

    grid_column_span_style = "grid-column: span #{n} / span #{n}"

    active_ordinal_value =
      assigns.scale.ordinal_values
      |> Enum.find(&(assigns.entry && assigns.entry.ordinal_value_id == &1.id))

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)
      |> assign(:grid_column_span_style, grid_column_span_style)
      |> assign(:active_ordinal_value, active_ordinal_value)

    ~H"""
    <div class={["grid gap-1 min-w-full", @class]} id={@id} style={@grid_template_columns_style}>
      <div class="grid grid-cols-subgrid" style={@grid_column_span_style}>
        <div
          :for={ordinal_value <- @scale.ordinal_values}
          class="p-2 rounded-sm font-mono text-xs text-center text-ltrn-subtle whitespace-nowrap bg-ltrn-lighter"
          style={
            if @entry && @entry.ordinal_value_id == ordinal_value.id,
              do: create_color_map_style(ordinal_value)
          }
        >
          {ordinal_value.name}
        </div>
      </div>
      <div :if={@rubric} class="grid grid-cols-subgrid" style={@grid_column_span_style}>
        <.markdown
          :for={descriptor <- @rubric.descriptors}
          class="p-4 rounded-sm bg-ltrn-lighter"
          style={
            if @active_ordinal_value && @active_ordinal_value.id == descriptor.ordinal_value_id,
              do: create_color_map_style(@active_ordinal_value),
              else: "color: #94a3b8"
          }
          text={descriptor.descriptor}
        />
      </div>
    </div>
    """
  end

  attr :entry, :any, required: true
  attr :ordinal_value, :map, required: true
  attr :descriptor, :map, required: true

  defp report_scale_descriptor(assigns) do
    %{entry: entry, ordinal_value: ordinal_value} = assigns
    is_active = entry && entry.ordinal_value_id == ordinal_value.id
    color_map_style = if is_active, do: create_color_map_style(ordinal_value)
    color_map_text_style = if is_active, do: create_color_map_text_style(ordinal_value)

    assigns =
      assigns
      |> assign(:color_map_style, color_map_style)
      |> assign(:color_map_text_style, color_map_text_style)

    ~H"""
    <div
      class="p-2 border border-ltrn-lighter rounded-sm font-mono bg-ltrn-lightest"
      style={@color_map_style}
    >
      <div
        class="p-1 rounded-xs text-xs text-center text-ltrn-subtle bg-ltrn-lighter shadow-lg"
        style={@color_map_style}
      >
        {@ordinal_value.name}
      </div>
      <.markdown
        text={@descriptor.descriptor}
        class="mt-2 text-[0.75rem]"
        style={@color_map_text_style}
      />
    </div>
    """
  end

  @doc """
  Renders a numeric scale as a horizontal gradient bar with an optional score marker.
  """
  attr :scale, Scale, required: true
  attr :score, :float, default: nil
  attr :is_student, :boolean, default: false
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def report_scale_numeric_bar(assigns) do
    score_left =
      if assigns.score,
        do: "#{Float.round(assigns.score * 100 / assigns.scale.max_score, 4)}%"

    assigns = assign(assigns, :score_left, score_left)

    ~H"""
    <div id={@id} class={["w-full", @class]}>
      <div
        class="flex items-center justify-between rounded-sm w-full h-6 px-2 font-mono text-xs text-ltrn-subtle bg-ltrn-lighter"
        style={create_color_map_gradient_bg_style(@scale)}
      >
        <div style={if @scale.start_text_color, do: "color: #{@scale.start_text_color}"}>
          0
        </div>
        <div
          class="text-right"
          style={if @scale.stop_text_color, do: "color: #{@scale.stop_text_color}"}
        >
          {format_float(@scale.max_score)}
        </div>
      </div>
      <.report_scale_marker
        :if={@score}
        left={@score_left}
        label={@score}
        is_student={@is_student}
      />
    </div>
    """
  end

  @doc false
  # Shared marker rendered below a report scale bar: a tip pointing to the exact
  # position plus a label box. Used by both the numeric and ordinal scale bars.
  attr :left, :string, required: true
  attr :label, :any, required: true
  attr :is_student, :boolean, default: false

  defp report_scale_marker(assigns) do
    ~H"""
    <div class="relative h-8">
      <div
        class="absolute top-0 flex flex-col items-center -translate-x-1/2"
        style={"left: #{@left}"}
      >
        <div class={[
          "w-0 h-0 border-x-4 border-x-transparent border-b-4",
          if(@is_student, do: "border-b-ltrn-student-dark", else: "border-b-ltrn-dark")
        ]}>
        </div>
        <div class={[
          "flex items-center justify-center px-2 h-6 rounded-sm font-sans text-sm shadow-lg whitespace-nowrap",
          if(@is_student,
            do: "text-ltrn-student-dark bg-ltrn-student-lighter",
            else: "text-ltrn-dark bg-white"
          )
        ]}>
          {@label}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders an ordinal scale as a segmented bar.

  Each ordinal value becomes a colored segment, ordered by `normalized_value`, with the
  segment width defined by the scale's `breakpoints` and the color taken from the ordinal
  value's `bg_color`/`text_color`. Each segment is a `<.tooltip>` area showing the ordinal
  value name and its range. When an `entry` with a `normalized_value` is given, a marker
  with that value is positioned below the bar, with a tip pointing to the exact position.

  Requires the scale's `ordinal_values` preload.
  """
  attr :scale, Scale, required: true
  attr :entry, :any, default: nil
  attr :id, :string, required: true
  attr :class, :any, default: nil

  def report_scale_ordinal_bar(assigns) do
    segments = build_ordinal_segments(assigns.scale)
    normalized_value = assigns.entry && assigns.entry.normalized_value
    last_index = length(segments) - 1

    marker_left = if normalized_value, do: "#{Float.round(normalized_value * 100, 4)}%"

    assigns =
      assigns
      |> assign(:segments, segments)
      |> assign(:normalized_value, normalized_value)
      |> assign(:last_index, last_index)
      |> assign(:marker_left, marker_left)

    ~H"""
    <div id={@id} class={["w-full", @class]}>
      <div class="relative flex items-stretch w-full h-6">
        <div
          :for={{segment, i} <- Enum.with_index(@segments)}
          class={[
            "relative h-full",
            i == 0 && "rounded-l-sm",
            i == @last_index && "rounded-r-sm"
          ]}
          style={"width: #{segment.width}%; #{create_color_map_style(segment.ordinal_value)}"}
        >
          <.tooltip id={"#{@id}-seg-#{i}"}>
            <div class="font-bold">{segment.ordinal_value.name}</div>
            <div :if={ordinal_segment_range_text(segment.lower, segment.upper)}>
              {ordinal_segment_range_text(segment.lower, segment.upper)}
            </div>
          </.tooltip>
        </div>
      </div>
      <.report_scale_marker
        :if={@normalized_value}
        left={@marker_left}
        label={format_normalized(@normalized_value)}
      />
    </div>
    """
  end

  defp build_ordinal_segments(%Scale{ordinal_values: ordinal_values} = scale) do
    breakpoints = scale.breakpoints || []
    lowers = [nil | breakpoints]
    uppers = breakpoints ++ [nil]

    [ordinal_values, lowers, uppers]
    |> Enum.zip()
    |> Enum.map(fn {ordinal_value, lower, upper} ->
      width = Float.round(((upper || 1.0) - (lower || 0.0)) * 100, 4)

      %{ordinal_value: ordinal_value, lower: lower, upper: upper, width: width}
    end)
  end

  defp ordinal_segment_range_text(nil, nil), do: nil

  defp ordinal_segment_range_text(nil, upper),
    do: gettext("Less than %{n}", n: format_float(upper))

  defp ordinal_segment_range_text(lower, nil),
    do: gettext("Greater than or equal to %{n}", n: format_float(lower))

  defp ordinal_segment_range_text(lower, upper),
    do:
      gettext("Greater than or equal to %{lower}, less than %{upper}",
        lower: format_float(lower),
        upper: format_float(upper)
      )

  attr :footnote, :string, required: true
  attr :class, :any, default: nil

  def footnote(assigns) do
    ~H"""
    <div
      :if={@footnote}
      class={[
        "py-6 bg-ltrn-diff-lightest",
        "sm:py-10",
        @class
      ]}
    >
      <.responsive_container>
        <div class="flex items-center justify-center w-10 h-10 rounded-full mb-6 text-ltrn-diff-lightest bg-ltrn-diff-accent">
          <.icon name="hero-document-text" />
        </div>
        <.markdown text={@footnote} />
      </.responsive_container>
    </div>
    """
  end

  attr :assessment_point, AssessmentPoint, required: true
  attr :entry, :any, required: true
  attr :id, :string, required: true
  attr :class, :any, default: nil

  def moment_assessment_point_entry(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <div class="flex items-center gap-4">
        <.badge :if={@assessment_point.is_differentiation} theme="diff">
          {gettext("Diff")}
        </.badge>
        <p class="flex-1 text-base font-bold">{@assessment_point.name}</p>
        <.assessment_point_entry_badge
          entry={@entry}
          class="shrink-0"
          show_stop
        />
      </div>
      <.markdown
        :if={@assessment_point.report_info}
        text={@assessment_point.report_info}
        class="my-6"
      />
      <.rubric_area
        :if={@entry.differentiation_rubric || @assessment_point.rubric}
        rubric={@entry.differentiation_rubric || @assessment_point.rubric}
        entry={@entry}
        id={"#{@id}-rubric"}
        class="mt-4"
      />
      <.comment_area :if={@entry && @entry.report_note} comment={@entry.report_note} class="mt-2" />
      <.attachments_list
        :if={@entry && is_list(@entry.evidences) && @entry.evidences != []}
        id={"#{@id}-attachments"}
        attachments={@entry.evidences}
        class="mt-4"
      />
    </div>
    """
  end

  @doc """
  Renders a student moments entries grid for a given report card.
  """

  attr :students_stream, :any, required: true
  attr :has_students, :boolean, required: true

  attr :strands, :list,
    required: true,
    doc: "requires `assessment_points_count` field to be calculated"

  attr :students_entries_map, :map, required: true
  attr :class, :any, default: nil

  def students_moments_entries_grid(assigns) do
    assessment_points_count =
      assigns.strands
      |> Enum.reduce(0, fn strand, count -> count + strand.assessment_points_count end)

    grid_template_columns_style =
      case assessment_points_count do
        n when n > 0 ->
          "grid-template-columns: 200px repeat(#{n}, minmax(0, max-content))"

        _ ->
          "grid-template-columns: 200px minmax(10px, 1fr)"
      end

    grid_column_style =
      case assessment_points_count do
        0 -> "grid-column: span 2 / span 2"
        n -> "grid-column: span #{n + 1} / span #{n + 1}"
      end

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)
      |> assign(:grid_column_style, grid_column_style)

    ~H"""
    <div class={[
      "relative w-full max-h-screen bg-white shadow-xl overflow-x-auto",
      @class
    ]}>
      <div class="relative grid gap-1 w-max min-w-full" style={@grid_template_columns_style}>
        <div
          class="sticky top-0 z-20 grid grid-cols-subgrid py-1 pr-1 bg-white"
          style={@grid_column_style}
        >
          <div class="sticky left-0 bg-white min-h-8"></div>
          <%= if @strands != [] do %>
            <div
              :for={strand <- @strands}
              id={"moments-entries-grid-strand-#{strand.id}"}
              class="relative"
              style={"grid-column: span #{strand.assessment_points_count} / span #{strand.assessment_points_count}"}
            >
              <a
                href={"/strands/#{strand.id}/assessment"}
                target="_blank"
                class="absolute inset-0 p-1 rounded-xs border border-ltrn-lighter font-display font-black text-sm text-center truncate bg-white hover:bg-ltrn-lighter"
                title={"#{if strand.type, do: "#{strand.type} | "}#{strand.name}"}
              >
                {if strand.type, do: "#{strand.type} | "}
                {strand.name}
              </a>
            </div>
          <% else %>
            <div class="w-full p-2 rounded-sm text-ltrn-subtle text-center bg-ltrn-lightest">
              {gettext("No strands with moments assessment linked to this report card")}
            </div>
          <% end %>
        </div>
        <%= if @has_students do %>
          <div
            :for={{dom_id, student} <- @students_stream}
            id={dom_id}
            class="group grid grid-cols-subgrid items-center pr-1 hover:bg-ltrn-mesh-cyan"
            style={@grid_column_style}
          >
            <div
              class="sticky left-0 z-10 p-2 text-xs truncate bg-white group-hover:bg-ltrn-mesh-cyan"
              title={student.name}
            >
              {student.name}
            </div>
            <%= if @strands != [] do %>
              <%= for strand
          <-
            @strands
            do %>
                <%= for {_moment_id, assessment_point_id, entry} <- @students_entries_map[student.id][strand.id] do %>
                  <a
                    href={"/strands/#{strand.id}/assessment/marking"}
                    target="_blank"
                    class="block w-full rounded-xs outline-ltrn-primary text-center hover:outline"
                  >
                    <.live_component
                      module={EntryParticleComponent}
                      id={"student-#{student.id}-ap-#{assessment_point_id}"}
                      entry={entry}
                      size="sm"
                      class="w-full"
                    />
                  </a>
                <% end %>
              <% end %>
            <% else %>
              <div class="h-full rounded-sm border border-ltrn-lighter bg-ltrn-lightest"></div>
            <% end %>
          </div>
        <% else %>
          <div class="grid grid-cols-subgrid" style={@grid_column_style}>
            <div class="p-4 rounded-sm text-ltrn-subtle bg-ltrn-lightest">
              {gettext("No students linked to this grade report")}
            </div>
            <%= if @strands != [] do %>
              TBD
            <% else %>
              <div class="rounded-sm border border-ltrn-lighter bg-ltrn-lightest"></div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders the breakdown of a composed assessment point: one row per component (with its
  marking and weight) plus the composed total.

  Set `mask_hidden_components` to mask the marking of components flagged `is_hidden`
  (the row and weight still render, only the value is hidden), and `mask_composed` to mask
  the composed total's value (e.g. when the composed assessment point itself is hidden).
  """

  attr :breakdown, :map, required: true
  attr :composed_name, :string, required: true
  attr :mask_hidden_components, :boolean, default: false
  attr :mask_composed, :boolean, default: false
  attr :component_patch_fn, :any, default: nil
  attr :class, :any, default: nil

  def composition_breakdown_table(assigns) do
    rows =
      Enum.map(assigns.breakdown.components, fn row ->
        masked = assigns.mask_hidden_components and row.assessment_point.is_hidden

        row =
          if masked do
            row
            |> Map.merge(%{ordinal_value: nil, score: nil, normalized_value: nil})
            |> Map.put(:masked, true)
          else
            Map.put(row, :masked, false)
          end

        patch =
          if assigns.component_patch_fn && not masked,
            do: assigns.component_patch_fn.(row.assessment_point.id)

        Map.put(row, :patch, patch)
      end)

    composed =
      if assigns.mask_composed do
        assigns.breakdown.composed
        |> Map.merge(%{ordinal_value: nil, score: nil, normalized_value: nil})
        |> Map.put(:masked, true)
      else
        Map.put(assigns.breakdown.composed, :masked, false)
      end

    assigns =
      assigns
      |> assign(:rows, rows)
      |> assign(:composed, composed)

    render_composition_breakdown_table(assigns)
  end

  defp render_composition_breakdown_table(%{breakdown: %{scale_type: "numeric"}} = assigns) do
    ~H"""
    <table class={
      [
        # widen by 1rem and pull back with -mx-2 so the margin-box still fills 100%
        # (no overflow) while the hover highlight gets breathing room past the edge
        # columns, which keep their content aligned via pl-2/pr-2
        "w-[calc(100%_+_1rem)] -mx-2 border-collapse font-sans text-sm",
        "[&_tr>*:first-child]:pl-2 [&_tr>*:last-child]:pr-2",
        @class
      ]
    }>
      <thead>
        <tr class="text-ltrn-subtle">
          <th class="w-full py-2 font-bold text-left">{gettext("Assessment point")}</th>
          <th class="py-2 pl-4 font-bold text-right whitespace-nowrap">
            {gettext("Student score")}
          </th>
          <th class="py-2 pl-4 font-bold text-right">{gettext("Max")}</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={row <- @rows} class="hover:bg-white">
          <td class="w-full py-2">
            <.link :if={row.patch} patch={row.patch} class="underline hover:text-ltrn-subtle">
              {row.assessment_point.name}
            </.link>
            <span :if={!row.patch}>{row.assessment_point.name}</span>
          </td>
          <td class="py-2 pl-4 text-right tabular-nums whitespace-nowrap">
            <span :if={is_number(row.score)}>{format_float(row.score)}</span>
            <span :if={!is_number(row.score)} class="text-ltrn-subtle">
              {breakdown_no_value_label(row)}
            </span>
          </td>
          <td class="py-2 pl-4 text-right tabular-nums text-ltrn-subtle">
            {format_max(row.assessment_point.scale.max_score)}
          </td>
        </tr>
        <tr class="font-bold">
          <td class="w-full py-2">{@composed_name}</td>
          <td class="py-2 pl-4 text-right tabular-nums">
            <span :if={is_number(@composed.score)}>
              {format_float(@composed.score)}
            </span>
            <span :if={!is_number(@composed.score)} class="text-ltrn-subtle">
              {if @composed.masked, do: gettext("Not available"), else: "—"}
            </span>
          </td>
          <td class="py-2 pl-4 text-right tabular-nums">
            {format_max(@composed.max_score)}
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  defp render_composition_breakdown_table(%{breakdown: %{scale_type: "ordinal"}} = assigns) do
    ~H"""
    <table class={
      [
        # widen by 1rem and pull back with -mx-2 so the margin-box still fills 100%
        # (no overflow) while the hover highlight gets breathing room past the edge
        # columns, which keep their content aligned via pl-2/pr-2
        "w-[calc(100%_+_1rem)] -mx-2 border-collapse font-sans text-sm",
        "[&_tr>*:first-child]:pl-2 [&_tr>*:last-child]:pr-2",
        @class
      ]
    }>
      <thead>
        <tr class="text-ltrn-subtle">
          <th class="w-full py-2 font-bold text-left">{gettext("Assessment point")}</th>
          <th class="py-2 pl-4 font-bold text-right">{gettext("Value")}</th>
          <th class="py-2 pl-4 font-bold text-right">{gettext("Normalized")}</th>
          <th class="py-2 pl-4 font-bold text-right">{gettext("Weight")}</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={row <- @rows} class="hover:bg-white">
          <td class="w-full py-2">
            <.link :if={row.patch} patch={row.patch} class="underline hover:text-ltrn-subtle">
              {row.assessment_point.name}
            </.link>
            <span :if={!row.patch}>{row.assessment_point.name}</span>
          </td>
          <td class="py-2 pl-4 text-right">
            <.badge :if={row.ordinal_value} color_map={row.ordinal_value}>
              {ov_short(row.ordinal_value)}
            </.badge>
            <span :if={is_nil(row.ordinal_value)} class="text-ltrn-subtle whitespace-nowrap">
              {breakdown_no_value_label(row)}
            </span>
          </td>
          <td class="py-2 pl-4 text-right tabular-nums text-ltrn-subtle">
            {format_normalized(row.normalized_value)}
          </td>
          <td class="py-2 pl-4 text-right tabular-nums text-ltrn-subtle">
            {format_float(row.weight)}
          </td>
        </tr>
        <tr class="font-bold">
          <td class="w-full py-2">{@composed_name}</td>
          <td class="py-2 pl-4 text-right">
            <.badge :if={@composed.ordinal_value} color_map={@composed.ordinal_value}>
              {ov_short(@composed.ordinal_value)}
            </.badge>
            <span :if={is_nil(@composed.ordinal_value)} class="text-ltrn-subtle">
              {if @composed.masked, do: gettext("Not available"), else: "—"}
            </span>
          </td>
          <td class="py-2 pl-4 text-right tabular-nums">
            {format_normalized(@composed.normalized_value)}
          </td>
          <td class="py-2 pl-4 text-right tabular-nums">
            {format_float(@breakdown.total_weight)}
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  defp breakdown_no_value_label(%{masked: true}), do: gettext("Not available")
  defp breakdown_no_value_label(%{is_missing: true}), do: gettext("Lack of evidence")
  defp breakdown_no_value_label(_), do: gettext("No marking")

  defp format_max(nil), do: "—"
  defp format_max(max_score), do: format_float(max_score)
end
