defmodule LantternWeb.ClassLive.ILPComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.Filters
  alias Lanttern.ILPFixtures
  alias Lanttern.SchoolsFixtures

  @live_view_base_path "/school/classes"

  setup [:register_and_log_in_staff_member]

  describe "ILP live view basic navigation" do
    test "no registered templates", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{class.id}/ilp")

      assert view
             |> has_element?(
               "p",
               "No ILP templates registered in your school. Talk to your Lanttern school manager."
             )
    end

    test "view students ILPs", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      cycle_id = user.current_profile.current_school_cycle.id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id, cycle_id: cycle_id})

      student_a =
        SchoolsFixtures.student_fixture(%{
          name: "aaa",
          school_id: school_id,
          classes_ids: [class.id]
        })

      student_b =
        SchoolsFixtures.student_fixture(%{
          name: "bbb",
          school_id: school_id,
          classes_ids: [class.id]
        })

      student_c =
        SchoolsFixtures.student_fixture(%{
          name: "ccc",
          school_id: school_id,
          classes_ids: [class.id]
        })

      template = ILPFixtures.ilp_template_fixture(%{school_id: school_id})

      _student_a_ilp =
        ILPFixtures.student_ilp_fixture(%{
          school_id: school_id,
          cycle_id: cycle_id,
          student_id: student_a.id,
          template_id: template.id
        })

      # setup current user template
      Filters.set_profile_current_filters(user, %{ilp_template_id: template.id})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{class.id}/ilp")

      assert view |> has_element?("div", "1 of 3 ILPs created")
      assert view |> has_element?("#student-#{student_a.id} a span", "View ILP")
      assert view |> has_element?("#student-#{student_b.id} a span", "Create ILP")
      assert view |> has_element?("#student-#{student_c.id} a span", "Create ILP")
    end
  end
end
