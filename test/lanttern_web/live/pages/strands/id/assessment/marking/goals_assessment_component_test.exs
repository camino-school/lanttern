defmodule LantternWeb.MarkingLive.GoalsAssessmentComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.AssessmentsFixtures
  alias Lanttern.Filters
  alias Lanttern.GradingFixtures
  alias Lanttern.LearningContextFixtures
  alias Lanttern.SchoolsFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_staff_member, :prepare]

  describe "Assessment views" do
    test "display teacher view", %{
      conn: conn,
      user: user,
      strand: strand,
      class: class,
      student: student,
      ordinal_value_1: ordinal_value_1
    } do
      # setup current user view
      Filters.set_profile_current_filters(user, %{assessment_view: "teacher"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}/assessment/marking")

      assert view |> has_element?("button", class.name)
      assert view |> has_element?("div", student.name)
      assert view |> has_element?("option[selected]", ordinal_value_1.name)
    end

    test "display student view", %{
      conn: conn,
      user: user,
      strand: strand,
      class: class,
      student: student,
      ordinal_value_2: ordinal_value_2
    } do
      # setup current user view
      Filters.set_profile_current_filters(user, %{assessment_view: "student"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}/assessment/marking")

      assert view |> has_element?("button", class.name)
      assert view |> has_element?("div", student.name)
      assert view |> has_element?("option[selected]", ordinal_value_2.name)
    end

    test "display compare view", %{
      conn: conn,
      user: user,
      strand: strand,
      class: class,
      student: student,
      ordinal_value_1: ordinal_value_1,
      ordinal_value_2: ordinal_value_2
    } do
      # setup current user view
      Filters.set_profile_current_filters(user, %{assessment_view: "compare"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}/assessment/marking")

      assert view |> has_element?("button", class.name)
      assert view |> has_element?("div", student.name)
      assert view |> has_element?("span", ordinal_value_1.name)
      assert view |> has_element?("span", ordinal_value_2.name)
    end
  end

  defp prepare(%{user: user}) do
    strand = LearningContextFixtures.strand_fixture()

    school_id = user.current_profile.school_id
    class = SchoolsFixtures.class_fixture(%{school_id: school_id})
    student = SchoolsFixtures.student_fixture(%{school_id: school_id, classes_ids: [class.id]})

    scale = GradingFixtures.scale_fixture(%{type: "ordinal"})

    ordinal_value_1 =
      GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, name: "ov_1 name abc"})

    ordinal_value_2 =
      GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, name: "ov_2 name abc"})

    assessment_point =
      AssessmentsFixtures.assessment_point_fixture(%{strand_id: strand.id, scale_id: scale.id})

    _entry_fixture =
      AssessmentsFixtures.assessment_point_entry_fixture(%{
        student_id: student.id,
        assessment_point_id: assessment_point.id,
        scale_id: scale.id,
        scale_type: scale.type,
        ordinal_value_id: ordinal_value_1.id,
        student_ordinal_value_id: ordinal_value_2.id
      })

    # setup current user class filter
    Filters.set_profile_strand_filters(user, strand.id, %{classes_ids: [class.id]})

    {:ok,
     strand: strand,
     class: class,
     student: student,
     ordinal_value_1: ordinal_value_1,
     ordinal_value_2: ordinal_value_2}
  end
end
