defmodule LantternWeb.StrandReport.StrandReportOverviewTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  # rubrics have no ExMachina factory yet, so we lean on the fixture for them
  alias Lanttern.RubricsFixtures

  # student path: /strand_report/:strand_report_id
  # staff path:   /student_report_cards/:student_report_card_id/strand_report/:strand_report_id

  describe "overview description toggle" do
    test "expands the clamped overview into full markdown and collapses back", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      strand = insert(:strand, description: "# Heading\n\nThis is **bold** text.")
      strand_report = insert(:strand_report, strand: strand)

      insert(:student_report_card,
        student: student,
        report_card: strand_report.report_card,
        allow_access: true
      )

      conn
      |> visit(~p"/strand_report/#{strand_report.id}")
      # collapsed: markdown is stripped to plain text, no formatting
      |> refute_has(".prose strong")
      |> assert_has("button", text: "Read the full overview")
      |> click_button("Read the full overview")
      # expanded: full markdown formatting is rendered
      |> assert_has(".prose strong")
      |> assert_has("button", text: "Show less")
      |> click_button("Show less")
      |> refute_has(".prose strong")
      |> assert_has("button", text: "Read the full overview")
    end
  end

  describe "moments rendering" do
    test "only renders moments that have a description or at least one lesson", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      strand = insert(:strand)
      strand_report = insert(:strand_report, strand: strand)

      insert(:student_report_card,
        student: student,
        report_card: strand_report.report_card,
        allow_access: true
      )

      insert(:moment, strand: strand, name: "Moment with description", description: "Some text")

      moment_with_lesson =
        insert(:moment, strand: strand, name: "Moment with lesson", description: nil)

      insert(:lesson,
        strand: strand,
        moment: moment_with_lesson,
        is_published: true,
        name: "A published lesson"
      )

      insert(:moment, strand: strand, name: "Empty moment", description: nil)

      conn
      |> visit(~p"/strand_report/#{strand_report.id}")
      |> assert_has("#strand-moments", text: "Moment with description")
      |> assert_has("#strand-moments", text: "Moment with lesson")
      |> refute_has("#strand-moments", text: "Empty moment")
    end
  end

  describe "rubrics tab visibility" do
    test "hides the rubrics tab when the strand has no rubrics to show", context do
      %{conn: conn, student: student} = register_and_log_in_student(context)

      strand_report = insert(:strand_report)

      insert(:student_report_card,
        student: student,
        report_card: strand_report.report_card,
        allow_access: true
      )

      conn
      |> visit(~p"/strand_report/#{strand_report.id}")
      |> refute_has("#strand-nav-tabs", text: "Rubrics")
    end

    test "shows the rubrics tab when the strand has rubrics to show", context do
      %{conn: conn, staff_member: staff_member} = register_and_log_in_staff_member(context)

      %{school: school} = Lanttern.Repo.preload(staff_member, :school)
      student = insert(:student, school: school)

      strand = insert(:strand)
      curriculum_item = insert(:curriculum_item)
      scale = insert(:scale)

      rubric =
        RubricsFixtures.rubric_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      insert(:assessment_point,
        strand: strand,
        curriculum_item: curriculum_item,
        scale: scale,
        rubric_id: rubric.id
      )

      strand_report = insert(:strand_report, strand: strand)

      student_report_card =
        insert(:student_report_card,
          student: student,
          report_card: strand_report.report_card
        )

      conn
      |> visit(
        ~p"/student_report_cards/#{student_report_card.id}/strand_report/#{strand_report.id}"
      )
      |> assert_has("#strand-nav-tabs", text: "Rubrics")
    end
  end
end
