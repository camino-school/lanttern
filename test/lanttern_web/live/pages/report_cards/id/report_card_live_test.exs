defmodule LantternWeb.ReportCardLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.ReportingFixtures

  alias Lanttern.LearningContextFixtures
  alias Lanttern.SchoolsFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_path_base "/report_cards"

  setup [:register_and_log_in_staff_member]

  describe "Report card live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn, user: user} do
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: user.current_profile.school_id})

      report_card =
        report_card_fixture(%{name: "Some report card name abc", school_cycle_id: cycle.id})

      conn = get(conn, "#{@live_view_path_base}/#{report_card.id}")

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Some report card name abc\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "report card overview", %{conn: conn, user: user} do
      cycle_2024 =
        SchoolsFixtures.cycle_fixture(%{
          school_id: user.current_profile.school_id,
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

    test "prevent user access to other schools report cards", %{conn: conn} do
      report_card = report_card_fixture()

      assert_raise(LantternWeb.NotFoundError, fn ->
        live(conn, "#{@live_view_path_base}/#{report_card.id}")
      end)
    end

    test "list students and students report cards", %{conn: conn, user: user} do
      parent_cycle = SchoolsFixtures.cycle_fixture(%{school_id: user.current_profile.school_id})

      subcycle =
        SchoolsFixtures.cycle_fixture(%{
          school_id: user.current_profile.school_id,
          parent_cycle_id: parent_cycle.id
        })

      year = TaxonomyFixtures.year_fixture()

      report_card = report_card_fixture(%{school_cycle_id: subcycle.id, year_id: year.id})

      class =
        SchoolsFixtures.class_fixture(%{
          school_id: user.current_profile.school_id,
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

      assert_redirect(view, "/student_report_cards/#{student_a_report_card.id}")
    end

    test "list strand reports", %{conn: conn, user: user} do
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: user.current_profile.school_id})
      report_card = report_card_fixture(%{school_cycle_id: cycle.id})

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

    test "view grades reports", %{conn: conn, user: user} do
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: user.current_profile.school_id})

      grades_report =
        Lanttern.GradesReportsFixtures.grades_report_fixture(%{
          school_cycle_id: cycle.id,
          name: "GR name AAA",
          info: "some GR info"
        })

      report_card =
        report_card_fixture(%{grades_report_id: grades_report.id, school_cycle_id: cycle.id})

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{report_card.id}/grades")

      assert view |> has_element?("a", "GR name AAA")
      assert view |> has_element?("p", "some GR info")
    end

    test "report card grading info takes precedence over grades report info", %{
      conn: conn,
      user: user
    } do
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: user.current_profile.school_id})

      grades_report =
        Lanttern.GradesReportsFixtures.grades_report_fixture(%{
          school_cycle_id: cycle.id,
          name: "GR name AAA",
          info: "some GR info"
        })

      report_card =
        report_card_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id,
          grading_info: "more important GR info"
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{report_card.id}/grades")

      assert view |> has_element?("a", "GR name AAA")
      assert view |> has_element?("p", "more important GR info")
    end

    test "view tracking", %{conn: conn, user: user} do
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: user.current_profile.school_id})
      report_card = report_card_fixture(school_cycle_id: cycle.id)

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{report_card.id}/tracking")

      assert view |> has_element?("p", "Add students to report card to track entries")
    end
  end

  describe "URL-based class filter" do
    setup %{conn: conn, user: user} do
      parent_cycle = SchoolsFixtures.cycle_fixture(%{school_id: user.current_profile.school_id})

      subcycle =
        SchoolsFixtures.cycle_fixture(%{
          school_id: user.current_profile.school_id,
          parent_cycle_id: parent_cycle.id
        })

      year = TaxonomyFixtures.year_fixture()
      report_card = report_card_fixture(%{school_cycle_id: subcycle.id, year_id: year.id})

      class_a =
        SchoolsFixtures.class_fixture(%{
          name: "Class AAA",
          school_id: user.current_profile.school_id,
          cycle_id: parent_cycle.id,
          years_ids: [year.id]
        })

      class_b =
        SchoolsFixtures.class_fixture(%{
          name: "Class BBB",
          school_id: user.current_profile.school_id,
          cycle_id: parent_cycle.id,
          years_ids: [year.id]
        })

      student_a =
        SchoolsFixtures.student_fixture(%{name: "Student AAA", classes_ids: [class_a.id]})

      student_b =
        SchoolsFixtures.student_fixture(%{name: "Student BBB", classes_ids: [class_b.id]})

      student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_a.id})
      student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_b.id})

      %{
        conn: conn,
        report_card: report_card,
        class_a: class_a,
        class_b: class_b,
        student_a: student_a,
        student_b: student_b
      }
    end

    test "lists all linked students when no classes_ids param is present", %{
      conn: conn,
      report_card: report_card,
      student_a: student_a,
      student_b: student_b
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{report_card.id}/students")

      assert view |> has_element?("#students-and-report-cards div", student_a.name)
      assert view |> has_element?("#students-and-report-cards div", student_b.name)
    end

    test "filters linked students by the classes_ids URL param", %{
      conn: conn,
      report_card: report_card,
      class_a: class_a,
      student_a: student_a,
      student_b: student_b
    } do
      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{report_card.id}/students?classes_ids=#{class_a.id}")

      assert view |> has_element?("#students-and-report-cards div", student_a.name)
      refute view |> has_element?("#students-and-report-cards div", student_b.name)
    end

    test "preserves the selected class filter across all tabs and the edit action", %{
      conn: conn,
      report_card: report_card,
      class_a: class_a
    } do
      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{report_card.id}/students?classes_ids=#{class_a.id}")

      # every tab link carries the filter
      assert view
             |> has_element?(
               "a[href='/report_cards/#{report_card.id}?classes_ids=#{class_a.id}']"
             )

      assert view
             |> has_element?(
               "a[href='/report_cards/#{report_card.id}/strands?classes_ids=#{class_a.id}']"
             )

      assert view
             |> has_element?(
               "a[href='/report_cards/#{report_card.id}/grades?classes_ids=#{class_a.id}']"
             )

      assert view
             |> has_element?(
               "a[href='/report_cards/#{report_card.id}/tracking?classes_ids=#{class_a.id}']"
             )

      # the edit report card action keeps the filter too
      assert view
             |> has_element?(
               "a[href='/report_cards/#{report_card.id}/students?classes_ids=#{class_a.id}&is_editing=true']"
             )
    end

    test "clicking a class badge applies the filter via the URL", %{
      conn: conn,
      report_card: report_card,
      class_a: class_a
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{report_card.id}/students")

      view
      |> element("#linked-students-classes-filter-#{class_a.id}")
      |> render_click()

      assert_patch(
        view,
        "#{@live_view_path_base}/#{report_card.id}/students?classes_ids=#{class_a.id}"
      )
    end

    test "clicking an already-selected class badge removes it from the URL", %{
      conn: conn,
      report_card: report_card,
      class_a: class_a
    } do
      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{report_card.id}/students?classes_ids=#{class_a.id}")

      view
      |> element("#linked-students-classes-filter-#{class_a.id}")
      |> render_click()

      assert_patch(view, "#{@live_view_path_base}/#{report_card.id}/students")
    end

    test "clicking the All badge clears the filter from the URL", %{
      conn: conn,
      report_card: report_card,
      class_a: class_a
    } do
      {:ok, view, _html} =
        live(conn, "#{@live_view_path_base}/#{report_card.id}/students?classes_ids=#{class_a.id}")

      view
      |> element("#linked-students-classes-filter-all")
      |> render_click()

      assert_patch(view, "#{@live_view_path_base}/#{report_card.id}/students")
    end
  end
end
