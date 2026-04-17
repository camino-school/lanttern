defmodule LantternWeb.StrandReport.EngagementTrackingTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.Engagement.DailyActiveProfile
  alias Lanttern.Engagement.StrandReportLessonView
  alias Lanttern.Engagement.StrandReportView
  alias Lanttern.Repo

  # student path: /strand_report/:strand_report_id
  # staff path:   /student_report_cards/:student_report_card_id/strand_report/:strand_report_id

  describe "DAU tracking" do
    test "records a daily active profile entry when a student visits the strand report",
         context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      strand_report = insert(:strand_report)

      insert(:student_report_card,
        student: student,
        report_card: strand_report.report_card,
        allow_student_access: true
      )

      conn
      |> visit(~p"/strand_report/#{strand_report.id}")

      assert [%DailyActiveProfile{}] = Repo.all(DailyActiveProfile)
    end

    test "does not duplicate DAU entry across multiple page visits in the same session",
         context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      strand_report = insert(:strand_report)

      insert(:student_report_card,
        student: student,
        report_card: strand_report.report_card,
        allow_student_access: true
      )

      conn
      |> visit(~p"/strand_report/#{strand_report.id}")

      conn
      |> visit(~p"/strand_report/#{strand_report.id}/rubrics")

      assert [%DailyActiveProfile{}] = Repo.all(DailyActiveProfile)
    end
  end

  describe "strand report view tracking — student path (navigation_context: strand_report)" do
    test "records a strand report view on overview tab visit", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      strand_report = insert(:strand_report)

      insert(:student_report_card,
        student: student,
        report_card: strand_report.report_card,
        allow_student_access: true
      )

      conn
      |> visit(~p"/strand_report/#{strand_report.id}")

      assert [%StrandReportView{tab: "overview", navigation_context: "strand_report"}] =
               Repo.all(StrandReportView)
    end

    test "records one view per tab per day, deduplicating revisits", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      strand_report = insert(:strand_report)

      insert(:student_report_card,
        student: student,
        report_card: strand_report.report_card,
        allow_student_access: true
      )

      conn |> visit(~p"/strand_report/#{strand_report.id}")
      conn |> visit(~p"/strand_report/#{strand_report.id}/rubrics")
      # revisit overview — should not create a second row
      conn |> visit(~p"/strand_report/#{strand_report.id}")

      views = Repo.all(StrandReportView)
      assert length(views) == 2
      assert Enum.any?(views, &(&1.tab == "overview"))
      assert Enum.any?(views, &(&1.tab == "rubrics"))
    end

    test "records all three trackable tabs as separate rows", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      strand_report = insert(:strand_report)

      insert(:student_report_card,
        student: student,
        report_card: strand_report.report_card,
        allow_student_access: true
      )

      conn |> visit(~p"/strand_report/#{strand_report.id}")
      conn |> visit(~p"/strand_report/#{strand_report.id}/rubrics")
      conn |> visit(~p"/strand_report/#{strand_report.id}/assessment")

      tabs = Repo.all(StrandReportView) |> Enum.map(& &1.tab) |> Enum.sort()
      assert tabs == ~w(assessment overview rubrics)
    end
  end

  describe "strand report view tracking — staff path (navigation_context: report_card)" do
    test "records a view with report_card navigation_context and student_report_card_id",
         context do
      %{conn: conn, staff_member: staff_member} = register_and_log_in_staff_member(context)

      %{school: school} = Repo.preload(staff_member, :school)
      student = insert(:student, school: school)
      strand_report = insert(:strand_report)

      student_report_card =
        insert(:student_report_card,
          student: student,
          report_card: strand_report.report_card
        )

      conn
      |> visit(
        ~p"/student_report_cards/#{student_report_card.id}/strand_report/#{strand_report.id}"
      )

      assert [
               %StrandReportView{
                 tab: "overview",
                 navigation_context: "report_card",
                 student_report_card_id: src_id
               }
             ] = Repo.all(StrandReportView)

      assert src_id == student_report_card.id
    end
  end

  describe "strand report lesson view tracking" do
    test "records a lesson view when a student opens a lesson in a strand report", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      strand_report = insert(:strand_report)
      lesson = insert(:lesson, strand: strand_report.strand, is_published: true)

      insert(:student_report_card,
        student: student,
        report_card: strand_report.report_card,
        allow_student_access: true
      )

      conn
      |> visit(~p"/strand_report/#{strand_report.id}/lesson/#{lesson.id}")

      assert [%StrandReportLessonView{lesson_id: lesson_id, strand_report_id: sr_id}] =
               Repo.all(StrandReportLessonView)

      assert lesson_id == lesson.id
      assert sr_id == strand_report.id
    end

    test "does not duplicate lesson view entry on page reload", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      strand_report = insert(:strand_report)
      lesson = insert(:lesson, strand: strand_report.strand, is_published: true)

      insert(:student_report_card,
        student: student,
        report_card: strand_report.report_card,
        allow_student_access: true
      )

      conn |> visit(~p"/strand_report/#{strand_report.id}/lesson/#{lesson.id}")
      conn |> visit(~p"/strand_report/#{strand_report.id}/lesson/#{lesson.id}")

      assert [%StrandReportLessonView{}] = Repo.all(StrandReportLessonView)
    end

    test "records lesson view with student_report_card_id on staff path", context do
      %{conn: conn, staff_member: staff_member} = register_and_log_in_staff_member(context)

      %{school: school} = Repo.preload(staff_member, :school)
      student = insert(:student, school: school)
      strand_report = insert(:strand_report)
      lesson = insert(:lesson, strand: strand_report.strand, is_published: true)

      student_report_card =
        insert(:student_report_card,
          student: student,
          report_card: strand_report.report_card
        )

      conn
      |> visit(
        ~p"/student_report_cards/#{student_report_card.id}/strand_report/#{strand_report.id}/lesson/#{lesson.id}"
      )

      assert [%StrandReportLessonView{student_report_card_id: src_id}] =
               Repo.all(StrandReportLessonView)

      assert src_id == student_report_card.id
    end
  end
end
