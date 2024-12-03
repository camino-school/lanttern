defmodule LantternWeb.ReportCardLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.ReportingFixtures

  alias Lanttern.LearningContextFixtures
  alias Lanttern.SchoolsFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_path_base "/report_cards"

  setup [:register_and_log_in_teacher]

  describe "Report card live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      report_card = report_card_fixture(%{name: "Some report card name abc"})

      conn = get(conn, "#{@live_view_path_base}/#{report_card.id}")

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Some report card name abc\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "report card overview", %{conn: conn} do
      cycle_2024 =
        SchoolsFixtures.cycle_fixture(%{
          start_at: ~D[2024-01-01],
          end_at: ~D[2024-12-31],
          name: "Cycle 2024"
        })

      report_card =
        report_card_fixture(%{school_cycle_id: cycle_2024.id, name: "Some report card name abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{report_card.id}")

      assert view |> has_element?("h1", report_card.name)
      assert view |> has_element?("span", "Cycle: Cycle 2024")
    end

    test "list students and students report cards", %{conn: conn} do
      school = SchoolsFixtures.school_fixture()
      parent_cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      subcycle =
        SchoolsFixtures.cycle_fixture(%{school_id: school.id, parent_cycle_id: parent_cycle.id})

      year = TaxonomyFixtures.year_fixture()

      report_card = report_card_fixture(%{school_cycle_id: subcycle.id, year_id: year.id})

      class =
        SchoolsFixtures.class_fixture(%{
          school_id: school.id,
          cycle_id: parent_cycle.id,
          years_ids: [year.id]
        })

      student_a = SchoolsFixtures.student_fixture(%{name: "Student AAA", classes_ids: [class.id]})

      _student_b =
        SchoolsFixtures.student_fixture(%{name: "Student BBB", classes_ids: [class.id]})

      student_a_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_a.id})

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{report_card.id}/students")

      # student A should be displayed in students linked to report card list
      assert view |> has_element?("div", "Student AAA")

      # student B should be displayed in students not linked to report card list
      # (students are filtered by the class from the same year and cycle as the report card)
      assert view |> has_element?("div", "Student BBB")

      view
      |> element("a[data-test-id='preview-button']")
      |> render_click()

      assert_redirect(view, "/student_report_card/#{student_a_report_card.id}")
    end

    test "list strand reports", %{conn: conn} do
      report_card = report_card_fixture()

      subject = TaxonomyFixtures.subject_fixture(%{name: "Some subject SSS"})
      year = TaxonomyFixtures.year_fixture(%{name: "Some year YYY"})

      strand =
        LearningContextFixtures.strand_fixture(%{
          name: "Strand for report ABC",
          type: "Some type XYZ",
          subjects_ids: [subject.id],
          years_ids: [year.id]
        })

      strand_report =
        strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand.id})

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{report_card.id}/strands")

      assert view
             |> has_element?("#strands_reports-#{strand_report.id} h5", "Strand for report ABC")

      assert view |> has_element?("#strands_reports-#{strand_report.id} p", "Some type XYZ")
      assert view |> has_element?("#strands_reports-#{strand_report.id} span", subject.name)
      assert view |> has_element?("#strands_reports-#{strand_report.id} span", year.name)
    end

    test "view grades reports", %{conn: conn} do
      grades_report = Lanttern.GradesReportsFixtures.grades_report_fixture(%{name: "GR name AAA"})
      report_card = report_card_fixture(%{grades_report_id: grades_report.id})

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{report_card.id}/grades")

      assert view |> has_element?("a", "GR name AAA")
    end

    test "view tracking", %{conn: conn} do
      report_card = report_card_fixture()

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{report_card.id}/tracking")

      assert view |> has_element?("h5", "Students moments assessment tracking")
    end
  end
end
