defmodule LantternWeb.MarkingLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.Assessments
  alias Lanttern.GradesReportsFixtures
  alias Lanttern.GradingFixtures
  alias Lanttern.Repo
  alias Lanttern.Schools

  @live_view_path "/strands"

  setup :register_and_log_in_staff_member

  defp prepare(%{user: user}) do
    school = Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
    strand = insert(:strand)
    class = insert(:class, school: school)
    insert(:class_assignment, strand: strand, class: class)

    {:ok, strand: strand, class: class, school: school}
  end

  describe "mount/3 - no class assignments" do
    test "shows prompt to assign classes when strand has no assignments", %{conn: conn} do
      strand = insert(:strand)

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> assert_has("button", text: "Assign classes to strand")
    end
  end

  describe "handle_params/3 - class filter initialization" do
    setup :prepare

    test "shows 'No filters applied' when visiting without classes_ids param", %{
      conn: conn,
      strand: strand
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> assert_has("button", text: "No filters applied")
    end

    test "discards non-assigned classes_ids from URL and defaults to all assigned classes", %{
      conn: conn,
      strand: strand,
      class: class,
      school: school
    } do
      other_class = insert(:class, school: school)

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{other_class.id}")
      |> assert_has("button", text: "1 filter")
      |> within("#strand-assessment-filter-modal", fn session ->
        # the assigned class should be the active selection, not the discarded one
        assert_has(session, "button", text: class.name)
      end)
    end

    test "assessment_view defaults to teacher when param is invalid", %{
      conn: conn,
      strand: strand
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?assessment_view=invalid")
      |> assert_has("button#view-dropdown-button", text: "Assessed by teacher")
    end

    test "respects valid assessment_view URL param", %{conn: conn, strand: strand} do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?assessment_view=student")
      |> assert_has("button#view-dropdown-button", text: "Assessed by students")
    end

    test "hides composition section in modal when strand has no composed APs", %{
      conn: conn,
      strand: strand
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> within("#strand-assessment-filter-modal", fn session ->
        refute_has(session, "p", text: "By grade composition")
      end)
    end
  end

  describe "handle_event/3 toggle_filter_class" do
    setup :prepare

    test "selecting a class and applying shows it as an active filter", %{
      conn: conn,
      strand: strand,
      class: class,
      school: school
    } do
      class2 = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class2)

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> within("#strand-assessment-filter-modal", fn session ->
        session
        |> click_button(class.name)
        |> click_button("Save")
      end)
      |> assert_has("button", text: "1 filter")
    end
  end

  describe "handle_event/3 clear_filter_selections" do
    setup :prepare

    test "clears draft class filter state and Save commits the clear", %{
      conn: conn,
      strand: strand,
      class: class
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> within("#strand-assessment-filter-modal", fn session ->
        session
        |> click_button("Clear all filters")
        |> click_button("Save")
      end)
      |> assert_has("button", text: "No filters applied")
    end
  end

  describe "Assessment views" do
    setup %{user: user} do
      school = Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      strand = insert(:strand)
      class = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class)

      scale = insert(:scale, school: school, type: "ordinal", breakpoints: [0.4, 0.8])
      ordinal_value_1 = insert(:ordinal_value, scale: scale, name: "ov_1 teacher abc")
      ordinal_value_2 = insert(:ordinal_value, scale: scale, name: "ov_2 student abc")

      assessment_point = insert(:assessment_point, strand_id: strand.id, scale: scale)

      student = insert(:student, school: school) |> Repo.preload(:classes)
      {:ok, student} = Schools.update_student(student, %{classes_ids: [class.id]})

      {:ok, _entry} =
        Assessments.create_assessment_point_entry(%{
          student_id: student.id,
          assessment_point_id: assessment_point.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ordinal_value_1.id,
          student_ordinal_value_id: ordinal_value_2.id
        })

      {:ok,
       strand: strand,
       class: class,
       student: student,
       ordinal_value_1: ordinal_value_1,
       ordinal_value_2: ordinal_value_2}
    end

    test "displays teacher assessment in teacher view", %{
      conn: conn,
      strand: strand,
      class: class,
      student: student,
      ordinal_value_1: ordinal_value_1
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> assert_has("div", text: student.name)
      |> assert_has("div", text: ordinal_value_1.name)
    end

    test "displays student self-assessment in student view", %{
      conn: conn,
      strand: strand,
      class: class,
      student: student,
      ordinal_value_2: ordinal_value_2
    } do
      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}&assessment_view=student"
      )
      |> assert_has("div", text: student.name)
      |> assert_has("div", text: ordinal_value_2.name)
    end

    test "displays both assessments in compare view", %{
      conn: conn,
      strand: strand,
      class: class,
      student: student,
      ordinal_value_1: ordinal_value_1,
      ordinal_value_2: ordinal_value_2
    } do
      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}&assessment_view=compare"
      )
      |> assert_has("div", text: student.name)
      |> assert_has("span", text: ordinal_value_1.name)
      |> assert_has("span", text: ordinal_value_2.name)
    end
  end

  describe "handle_event/3 apply_assessment_filters" do
    setup :prepare

    test "adds classes_ids param when a subset of assigned classes is in the filter", %{
      conn: conn,
      strand: strand,
      class: class,
      school: school
    } do
      class2 = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class2)

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> within("#strand-assessment-filter-modal", fn session ->
        click_button(session, "Save")
      end)
      |> assert_has("button", text: "1 filter")
    end

    test "removes classes_ids param when the filter matches all assigned classes", %{
      conn: conn,
      strand: strand,
      class: class
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> within("#strand-assessment-filter-modal", fn session ->
        click_button(session, "Save")
      end)
      |> assert_has("button", text: "No filters applied")
    end

    test "removes classes_ids param when no filter classes are selected", %{
      conn: conn,
      strand: strand
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> within("#strand-assessment-filter-modal", fn session ->
        click_button(session, "Save")
      end)
      |> assert_has("button", text: "No filters applied")
    end
  end

  describe "filter by grade composition" do
    setup %{user: user} do
      school = Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      strand = insert(:strand)
      class = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class)

      parent_ap =
        insert(:assessment_point,
          strand_id: strand.id,
          name: "Composition AP",
          uses_composition: true
        )

      component_ap_1 =
        insert(:assessment_point, strand_id: strand.id, name: "Component AP 1")

      component_ap_2 =
        insert(:assessment_point, strand_id: strand.id, name: "Component AP 2")

      insert(:assessment_point_component, parent: parent_ap, component: component_ap_1)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap_2)

      {:ok,
       strand: strand,
       class: class,
       parent_ap: parent_ap,
       component_ap_1: component_ap_1,
       component_ap_2: component_ap_2}
    end

    test "shows composition section in modal when strand has composed APs", %{
      conn: conn,
      strand: strand,
      parent_ap: parent_ap
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> within("#strand-assessment-filter-modal", fn session ->
        session
        |> assert_has("p", text: "By grade composition")
        |> assert_has("button", text: parent_ap.name)
      end)
    end

    test "selecting a composition AP and saving adds the composition_ap_id param", %{
      conn: conn,
      strand: strand,
      parent_ap: parent_ap
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> within("#strand-assessment-filter-modal", fn session ->
        session
        |> click_button(parent_ap.name)
        |> click_button("Save")
      end)
      |> assert_has("button", text: "1 filter")
    end

    test "visiting with composition_ap_id param shows filter as active", %{
      conn: conn,
      strand: strand,
      parent_ap: parent_ap
    } do
      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?composition_ap_id=#{parent_ap.id}"
      )
      |> assert_has("button", text: "1 filter")
    end

    test "clear_filter_selections clears composition selection and Save removes param", %{
      conn: conn,
      strand: strand,
      parent_ap: parent_ap
    } do
      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?composition_ap_id=#{parent_ap.id}"
      )
      |> within("#strand-assessment-filter-modal", fn session ->
        session
        |> click_button("Clear all filters")
        |> click_button("Save")
      end)
      |> assert_has("button", text: "No filters applied")
    end

    test "both class and composition filters active show '2 filters'", %{
      conn: conn,
      strand: strand,
      class: class,
      parent_ap: parent_ap
    } do
      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}&composition_ap_id=#{parent_ap.id}"
      )
      |> assert_has("button", text: "2 filters")
    end
  end

  describe "command palette" do
    setup %{user: user} do
      school = Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      strand = insert(:strand)
      class = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class)

      student = insert(:student, school: school) |> Repo.preload(:classes)
      {:ok, _student} = Schools.update_student(student, %{classes_ids: [class.id]})

      parent_ap =
        insert(:assessment_point,
          strand_id: strand.id,
          name: "Composition AP",
          uses_composition: true
        )

      component_ap =
        insert(:assessment_point, strand_id: strand.id, name: "Component AP")

      plain_ap =
        insert(:assessment_point, strand_id: strand.id, name: "Plain AP")

      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      {:ok,
       strand: strand,
       class: class,
       parent_ap: parent_ap,
       component_ap: component_ap,
       plain_ap: plain_ap}
    end

    test "command palette of an AP part of a composition opens with add composition button disabled",
         %{conn: conn, strand: strand, class: class} do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> within("#grid-assessment-points", &click_button(&1, "Component AP"))
      |> assert_has("button[disabled]", text: "Add grade composition")
      |> assert_has("p", text: "part of another grade composition")
      |> assert_has("li", text: "Composition AP")
    end

    test "command palette of a plain AP opens with an enabled add composition button", %{
      conn: conn,
      strand: strand,
      class: class
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> within("#grid-assessment-points", &click_button(&1, "Plain AP"))
      |> assert_has("button", text: "Add grade composition")
      |> refute_has("button[disabled]", text: "Add grade composition")
    end

    test "command palette of a composed AP opens with the manage composition button", %{
      conn: conn,
      strand: strand,
      class: class
    } do
      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> within("#grid-assessment-points", &click_button(&1, "Composition AP"))
      |> assert_has("button", text: "Manage grade composition")
    end
  end

  describe "grades report column group" do
    # marking only renders the grid (and thus the grades report group) when a
    # class is selected, the strand has at least one assessment point, and there
    # is an enrolled student. This adds those essentials for a given strand.
    defp add_marking_essentials(strand, school) do
      class = insert(:class, school: school)
      insert(:class_assignment, strand: strand, class: class)

      ap_scale = insert(:scale, school: school)
      assessment_point = insert(:assessment_point, strand_id: strand.id, scale: ap_scale)

      student = insert(:student, school: school) |> Repo.preload(:classes)
      {:ok, student} = Schools.update_student(student, %{classes_ids: [class.id]})

      %{class: class, student: student, assessment_point: assessment_point}
    end

    defp setup_grades_report_grid(%{user: user}, opts) do
      with_cycle = Keyword.get(opts, :with_cycle, true)
      school = Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)

      cycle = insert(:cycle, school: school)
      subject = insert(:subject, name: "Algebra Subject Xyz")
      scale = insert(:scale, school: school, type: "ordinal", breakpoints: [0.4, 0.8])
      ordinal_value = insert(:ordinal_value, scale: scale, name: "Great Grade Value")
      insert(:ordinal_value, scale: scale)

      grades_report = GradesReportsFixtures.grades_report_fixture(%{scale_id: scale.id})

      grs =
        GradesReportsFixtures.grades_report_subject_fixture(%{
          grades_report_id: grades_report.id,
          subject_id: subject.id
        })

      grc =
        if with_cycle do
          GradesReportsFixtures.grades_report_cycle_fixture(%{
            grades_report_id: grades_report.id,
            school_cycle_id: cycle.id
          })
        end

      report_card = insert(:report_card, school_cycle: cycle, grades_report_id: grades_report.id)

      strand = insert(:strand, subjects: [subject])
      insert(:strand_report, report_card: report_card, strand: strand)

      strand
      |> add_marking_essentials(school)
      |> Map.merge(%{
        strand: strand,
        subject: subject,
        scale: scale,
        ordinal_value: ordinal_value,
        cycle: cycle,
        grades_report: grades_report,
        grades_report_subject: grs,
        grades_report_cycle: grc
      })
    end

    test "renders the group and subject column header when a grades report card is linked",
         %{conn: conn} = context do
      %{strand: strand, class: class} = setup_grades_report_grid(context, [])

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> assert_has("span", text: "Grades report")
      |> assert_has("button", text: "Algebra Subject Xyz")
    end

    test "renders the student's existing grade in the cell", %{conn: conn} = context do
      %{
        strand: strand,
        class: class,
        student: student,
        ordinal_value: ordinal_value,
        grades_report: grades_report,
        grades_report_subject: grs,
        grades_report_cycle: grc
      } = setup_grades_report_grid(context, [])

      GradesReportsFixtures.student_grades_report_entry_fixture(%{
        student_id: student.id,
        grades_report_id: grades_report.id,
        grades_report_cycle_id: grc.id,
        grades_report_subject_id: grs.id,
        ordinal_value_id: ordinal_value.id,
        normalized_value: 0.9
      })

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> assert_has("button", text: "Great Grade Value")
    end

    test "does not render the group when no grades report is linked", %{conn: conn, user: user} do
      school = Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      strand = insert(:strand)
      %{class: class, student: student} = add_marking_essentials(strand, school)

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> assert_has("div", text: student.name)
      |> refute_has("span", text: "Grades report")
    end

    test "hides the group when a composition filter is active", %{conn: conn} = context do
      %{strand: strand, class: class, assessment_point: assessment_point} =
        setup_grades_report_grid(context, [])

      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}&composition_ap_id=#{assessment_point.id}"
      )
      |> refute_has("span", text: "Grades report")
    end

    test "disables the calculate buttons when the grades report cycle is not set",
         %{conn: conn} = context do
      %{strand: strand, class: class} = setup_grades_report_grid(context, with_cycle: false)

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> assert_has("button[disabled]", text: "Calculate subject grades")
      |> assert_has("button[disabled]", text: "Calculate grade")
    end

    test "calculating a cell with no composition entries flashes the no-entries message",
         %{conn: conn} = context do
      %{strand: strand, class: class} = setup_grades_report_grid(context, [])

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> click_button("Calculate grade")
      |> assert_has("[role='alert']",
        text: "No assessment point entries for this grade composition"
      )
    end

    test "calculating a subject flashes the success message", %{conn: conn} = context do
      %{strand: strand, class: class} = setup_grades_report_grid(context, [])

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> click_button("Calculate subject grades")
      |> assert_has("[role='alert']", text: "Subject grades calculated succesfully")
    end

    test "managing composition from the subject header opens the grade composition overlay",
         %{conn: conn} = context do
      %{strand: strand, class: class} = setup_grades_report_grid(context, [])

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> click_button("Manage grade composition")
      |> assert_has("div", text: "Grade composition not setup yet")
    end

    test "clicking a student grade opens the student grades report entry overlay",
         %{conn: conn} = context do
      %{
        strand: strand,
        class: class,
        student: student,
        ordinal_value: ordinal_value,
        grades_report: grades_report,
        grades_report_subject: grs,
        grades_report_cycle: grc
      } = setup_grades_report_grid(context, [])

      GradesReportsFixtures.student_grades_report_entry_fixture(%{
        student_id: student.id,
        grades_report_id: grades_report.id,
        grades_report_cycle_id: grc.id,
        grades_report_subject_id: grs.id,
        ordinal_value_id: ordinal_value.id,
        composition_ordinal_value_id: ordinal_value.id,
        normalized_value: 0.9,
        composition_datetime: ~U[2024-06-01 10:00:00Z]
      })

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
      |> click_button("Great Grade Value")
      |> assert_has("#student-grade-report-entry-overlay",
        text: "Edit student grades report entry"
      )
    end
  end

  describe "filter by grade report" do
    test "renders the section with a subject badge when a grades report card is linked",
         %{conn: conn} = context do
      %{strand: strand} = setup_grades_report_grid(context, [])

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> within("#strand-assessment-filter-modal", fn session ->
        session
        |> assert_has("p", text: "By grade report")
        |> assert_has("button", text: "Algebra Subject Xyz")
      end)
    end

    test "does not render the section when no grades report is linked",
         %{conn: conn, user: user} do
      school = Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      strand = insert(:strand)
      insert(:class_assignment, strand: strand, class: insert(:class, school: school))

      conn
      |> visit("#{@live_view_path}/#{strand.id}/assessment/marking")
      |> within("#strand-assessment-filter-modal", fn session ->
        refute_has(session, "p", text: "By grade report")
      end)
    end

    test "selecting a grade report shows its composition APs alongside the grade report column",
         %{conn: conn} = context do
      %{
        strand: strand,
        class: class,
        grades_report: grades_report,
        grades_report_subject: grs,
        grades_report_cycle: grc
      } = setup_grades_report_grid(context, [])

      goal_ap = insert(:assessment_point, strand_id: strand.id, name: "Goal In Composition")
      insert(:assessment_point, strand_id: strand.id, name: "Unrelated AP")

      GradingFixtures.grade_component_fixture(%{
        grades_report_id: grades_report.id,
        grades_report_cycle_id: grc.id,
        grades_report_subject_id: grs.id,
        assessment_point_id: goal_ap.id
      })

      session =
        conn
        |> visit("#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}")
        |> within("#strand-assessment-filter-modal", fn session ->
          session
          |> click_button("Algebra Subject Xyz")
          |> click_button("Save")
        end)

      session
      # the filter is applied...
      |> assert_has("button", text: "1 filter")
      # ...the composition's assessment point is shown...
      |> assert_has("p", text: "Goal In Composition")
      # ...unrelated assessment points are filtered out...
      |> refute_has("p", text: "Unrelated AP")
      # ...and the filtered grade report column group itself remains visible
      |> assert_has("span", text: "Grades report")
    end

    test "selecting a grade report clears a previously selected composition AP",
         %{conn: conn} = context do
      %{strand: strand} = setup_grades_report_grid(context, [])

      parent_ap =
        insert(:assessment_point,
          strand_id: strand.id,
          name: "Composition AP",
          uses_composition: true
        )

      # starting from an applied composition filter, selecting a grade report and
      # saving must replace it (not combine), so the count stays at a single filter
      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?composition_ap_id=#{parent_ap.id}"
      )
      |> within("#strand-assessment-filter-modal", fn session ->
        session
        |> click_button("Algebra Subject Xyz")
        |> click_button("Save")
      end)
      |> assert_has("button", text: "1 filter")
    end

    test "class and grade report filters combine to show '2 filters'",
         %{conn: conn} = context do
      %{strand: strand, class: class, grades_report_subject: grs, grades_report_cycle: grc} =
        setup_grades_report_grid(context, [])

      value = "#{grc.id}-#{grs.id}"

      conn
      |> visit(
        "#{@live_view_path}/#{strand.id}/assessment/marking?classes_ids=#{class.id}&grades_report_filter=#{value}"
      )
      |> assert_has("button", text: "2 filters")
    end
  end
end
