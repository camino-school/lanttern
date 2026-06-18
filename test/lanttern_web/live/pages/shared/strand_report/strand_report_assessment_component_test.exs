defmodule LantternWeb.StrandReportLive.StrandReportAssessmentComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.AssessmentsFixtures
  import Lanttern.Factory
  import Lanttern.ReportingFixtures

  alias Lanttern.LearningContextFixtures

  @live_view_path_base "/strand_report"

  defp setup_strand_report(context) do
    %{conn: conn, student: student} = register_and_log_in_student(context)

    report_card = report_card_fixture()

    student_report_card_fixture(%{
      report_card_id: report_card.id,
      student_id: student.id,
      allow_access: true
    })

    strand = LearningContextFixtures.strand_fixture()
    strand_report = strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand.id})

    %{conn: conn, student: student, strand: strand, strand_report: strand_report}
  end

  defp marked_entry(assessment_point_id, student_id, scale, ordinal_value_id) do
    assessment_point_entry_fixture(%{
      assessment_point_id: assessment_point_id,
      student_id: student_id,
      scale_id: scale.id,
      scale_type: scale.type,
      ordinal_value_id: ordinal_value_id
    })
  end

  describe "StrandReportAssessmentComponent" do
    test "renders moment names and assessment point cards for student entries", context do
      %{conn: conn, student: student, strand: strand, strand_report: strand_report} =
        setup_strand_report(context)

      moment =
        LearningContextFixtures.moment_fixture(%{strand_id: strand.id, name: "Moment Alpha"})

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      ap =
        assessment_point_fixture(%{
          name: "Assessment Point Alpha",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      marked_entry(ap.id, student.id, scale, ov.id)

      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{strand_report.id}/assessment")

      assert view |> has_element?("h4", "Moment Alpha")
      assert view |> has_element?("#strand-assessment-points", "Assessment Point Alpha")
    end

    test "does not show hidden non-composed assessment points", context do
      %{conn: conn, student: student, strand: strand, strand_report: strand_report} =
        setup_strand_report(context)

      moment =
        LearningContextFixtures.moment_fixture(%{strand_id: strand.id, name: "Moment Alpha"})

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      ap_visible =
        assessment_point_fixture(%{
          name: "AP Visible",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      ap_hidden =
        assessment_point_fixture(%{
          name: "AP Hidden",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id,
          is_hidden: true
        })

      marked_entry(ap_visible.id, student.id, scale, ov.id)
      marked_entry(ap_hidden.id, student.id, scale, ov.id)

      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{strand_report.id}/assessment")

      assert view |> has_element?("#strand-assessment-points", "AP Visible")
      refute view |> has_element?("#strand-assessment-points", "AP Hidden")
    end

    test "shows composed assessment points even without an own marked entry", context do
      %{conn: conn, student: student, strand: strand, strand_report: strand_report} =
        setup_strand_report(context)

      moment = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      composed_ap =
        assessment_point_fixture(%{
          name: "Composed AP",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id,
          uses_composition: true
        })

      component_ap =
        assessment_point_fixture(%{
          name: "Component AP",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      insert(:assessment_point_component, parent: composed_ap, component: component_ap)

      # the component has a marked entry (renders as a particle); the composed AP has none
      marked_entry(component_ap.id, student.id, scale, ov.id)

      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{strand_report.id}/assessment")

      assert view |> has_element?("#strand-assessment-points", "Composed AP")
    end

    test "shows hidden composed assessment points with their own marking masked", context do
      %{conn: conn, student: student, strand: strand, strand_report: strand_report} =
        setup_strand_report(context)

      moment = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      composed_ap =
        assessment_point_fixture(%{
          name: "Hidden Composed AP",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id,
          uses_composition: true,
          is_hidden: true
        })

      # the composed AP has an own marked entry, which must be masked because it is hidden
      marked_entry(composed_ap.id, student.id, scale, ov.id)

      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{strand_report.id}/assessment")

      assert view |> has_element?("#strand-assessment-points", "Hidden Composed AP")

      assert view
             |> has_element?("#strand-assessment-points", "Final assessment not available yet")
    end

    test "does not show non-composed assessment points that have no entry for the student",
         context do
      %{conn: conn, strand: strand, strand_report: strand_report} = setup_strand_report(context)

      moment =
        LearningContextFixtures.moment_fixture(%{strand_id: strand.id, name: "Moment Beta"})

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ci = insert(:curriculum_item)

      assessment_point_fixture(%{
        name: "AP Without Entry",
        moment_id: moment.id,
        scale_id: scale.id,
        curriculum_item_id: ci.id
      })

      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{strand_report.id}/assessment")

      refute view |> has_element?("h4", "Moment Beta")
      refute view |> has_element?("#strand-assessment-points", "AP Without Entry")
    end

    test "renders strand-level assessment cards and hides hidden non-composed ones", context do
      %{conn: conn, student: student, strand: strand, strand_report: strand_report} =
        setup_strand_report(context)

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      ap_visible =
        assessment_point_fixture(%{
          name: "Strand Goal Visible",
          strand_id: strand.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      ap_hidden =
        assessment_point_fixture(%{
          name: "Strand Goal Hidden",
          strand_id: strand.id,
          scale_id: scale.id,
          curriculum_item_id: insert(:curriculum_item).id,
          is_hidden: true
        })

      marked_entry(ap_visible.id, student.id, scale, ov.id)
      marked_entry(ap_hidden.id, student.id, scale, ov.id)

      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{strand_report.id}/assessment")

      assert view |> has_element?("h4", "Strand-level assessments")
      assert view |> has_element?("#strand-level-assessment-points", "Strand Goal Visible")
      refute view |> has_element?("#strand-level-assessment-points", "Strand Goal Hidden")
    end
  end

  describe "StudentAssessmentPointDetailsOverlayComponent" do
    test "renders assessment point details overlay when navigating to ap id path", context do
      %{conn: conn, student: student, strand: strand, strand_report: strand_report} =
        setup_strand_report(context)

      moment = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item, %{name: "Some Curriculum Item"})

      ap =
        assessment_point_fixture(%{
          name: "AP With Details",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      marked_entry(ap.id, student.id, scale, ov.id)

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{strand_report.id}/assessment/assessment_point/#{ap.id}"
        )

      assert view |> has_element?("h4", "AP With Details")
      assert view |> has_element?("p", "Some Curriculum Item")
    end

    test "renders the composition breakdown for a composed assessment point", context do
      %{conn: conn, student: student, strand: strand, strand_report: strand_report} =
        setup_strand_report(context)

      moment = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      composed_ap =
        assessment_point_fixture(%{
          name: "Composed AP",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id,
          uses_composition: true
        })

      component_ap =
        assessment_point_fixture(%{
          name: "Component AP",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      insert(:assessment_point_component, parent: composed_ap, component: component_ap)
      marked_entry(component_ap.id, student.id, scale, ov.id)

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{strand_report.id}/assessment/assessment_point/#{composed_ap.id}"
        )

      assert view |> has_element?("h5", "Grade composition")
      assert view |> has_element?("td", "Component AP")
    end

    test "does not render overlay for assessment points unrelated to the student", context do
      %{conn: conn, strand: strand, strand_report: strand_report} = setup_strand_report(context)

      moment = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ci = insert(:curriculum_item)

      # AP with no entry for the logged-in student (non-composed → not displayed/guarded)
      unrelated_ap =
        assessment_point_fixture(%{
          name: "Unrelated AP",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_path_base}/#{strand_report.id}/assessment/assessment_point/#{unrelated_ap.id}"
        )

      refute view |> has_element?("h3", "Unrelated AP")
    end
  end
end
