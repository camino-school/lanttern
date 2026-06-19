defmodule LantternWeb.StudentStrandsLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory

  alias Lanttern.AssessmentsFixtures
  alias Lanttern.LearningContextFixtures
  alias Lanttern.ReportingFixtures
  alias Lanttern.SchoolsFixtures

  @live_view_path "/student_strands"

  setup [:register_and_log_in_student]

  describe "Student strands live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Strands\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "list strands linked to report cards", %{conn: conn, user: user, student: student} do
      parent_cycle_id = user.current_profile.current_school_cycle.id

      cycle =
        SchoolsFixtures.cycle_fixture(%{
          school_id: student.school_id,
          parent_cycle_id: parent_cycle_id
        })

      report_card = ReportingFixtures.report_card_fixture(%{school_cycle_id: cycle.id})

      _student_report_card =
        ReportingFixtures.student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id,
          allow_access: true
        })

      strand_a = LearningContextFixtures.strand_fixture(%{name: "AAA"})
      strand_b = LearningContextFixtures.strand_fixture(%{name: "BBB"})

      _strand_a_report =
        ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_a.id
        })

      _strand_b_report =
        ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_b.id
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h5", "AAA")
      assert view |> has_element?("h5", "BBB")
    end

    test "does not display entry particles for hidden assessment points",
         %{conn: conn, user: user, student: student} do
      parent_cycle_id = user.current_profile.current_school_cycle.id

      cycle =
        SchoolsFixtures.cycle_fixture(%{
          school_id: student.school_id,
          parent_cycle_id: parent_cycle_id
        })

      report_card = ReportingFixtures.report_card_fixture(%{school_cycle_id: cycle.id})

      _student_report_card =
        ReportingFixtures.student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id,
          allow_access: true
        })

      strand = LearningContextFixtures.strand_fixture(%{name: "CCC"})

      strand_report =
        ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand.id
        })

      moment = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      scale = insert(:scale, type: "ordinal")
      ov_visible = insert(:ordinal_value, scale: scale, short_name: "ovx")
      ov_hidden = insert(:ordinal_value, scale: scale, short_name: "ovy")

      ap_visible =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment.id,
          scale_id: scale.id
        })

      ap_hidden =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment.id,
          scale_id: scale.id,
          is_hidden: true
        })

      _entry_visible =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: ap_visible.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_visible.id
        })

      _entry_hidden =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: ap_hidden.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_hidden.id
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h5", "CCC")
      assert view |> has_element?("#student-strand-report-#{strand_report.id}", "ovx")
      refute view |> has_element?("#student-strand-report-#{strand_report.id}", "ovy")
    end
  end
end
