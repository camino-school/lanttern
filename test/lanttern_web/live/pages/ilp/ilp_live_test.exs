defmodule LantternWeb.ILPLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory

  alias Lanttern.ILP.StudentILP
  alias Lanttern.Repo

  alias Lanttern.Filters
  alias Lanttern.ILP
  alias Lanttern.ILPFixtures
  alias Lanttern.SchoolsFixtures

  @live_view_path "/ilp/"

  setup [:register_and_log_in_staff_member]

  describe "ILP live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*ILP\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "no registered templates", %{conn: conn} do
      {:ok, view, _html} = live(conn, @live_view_path)

      assert view
             |> has_element?(
               "p",
               "No ILP templates registered in your school. Talk to your Lanttern school manager."
             )
    end

    test "no student selected", %{conn: conn, user: user} do
      template = ILPFixtures.ilp_template_fixture(%{school_id: user.current_profile.school_id})

      # setup current user template
      Filters.set_profile_current_filters(user, %{ilp_template_id: template.id})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("p", "No student selected")
    end

    test "no student ILP", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      template = ILPFixtures.ilp_template_fixture(%{school_id: school_id})
      student = SchoolsFixtures.student_fixture(%{school_id: school_id})

      # setup current user template and student
      Filters.set_profile_current_filters(user, %{ilp_template_id: template.id})
      Filters.set_profile_current_filters(user, %{student_id: student.id})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("p", "No student ILP created yet")
    end

    test "view student ILP", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id})

      template =
        ILPFixtures.ilp_template_fixture(%{
          name: "ILP abc",
          school_id: school_id,
          # needed to show AI box
          ai_layer: %{
            revision_instructions: "some ai revision instruction",
            model: "some model"
          }
        })
        |> Repo.preload(sections: :components)

      {:ok, %{sections: [%{components: [component]}]} = template} =
        ILP.update_ilp_template(template, %{
          sections: [
            %{
              name: "section 1",
              position: 0,
              components: [
                %{name: "component 1", template_id: template.id}
              ]
            }
          ]
        })

      student_ilp_params =
        %{
          school_id: school_id,
          cycle_id: user.current_profile.current_school_cycle.id,
          student_id: student.id,
          template_id: template.id,
          teacher_notes: "some teacher notes",
          entries: [
            %{
              template_id: template.id,
              component_id: component.id,
              description: "some entry description"
            }
          ]
        }

      ILPFixtures.student_ilp_fixture(student_ilp_params)

      # setup current user template and student
      Filters.set_profile_current_filters(user, %{ilp_template_id: template.id})
      Filters.set_profile_current_filters(user, %{student_id: student.id})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h4", "ILP abc")
      assert view |> has_element?("div", "section 1")
      assert view |> has_element?("div", "component 1")
      assert view |> has_element?("p", "some entry description")

      # ai review should be enabled for templates with revision instructions + complete ILP
      assert view
             |> has_element?(~s(input[placeholder="Student age"]))
    end

    test "share student ILP", context do
      %{conn: conn, user: user} = set_user_permissions(["ilp_management"], context)
      school = user.current_profile.staff_member.school
      student = insert(:student, school: school)
      template = insert(:ilp_template, school: school)

      student_ilp =
        insert(:student_ilp,
          school: school,
          cycle: user.current_profile.current_school_cycle,
          student: student,
          template: template
        )

      # setup current user template and student
      Filters.set_profile_current_filters(user, %{ilp_template_id: template.id})
      Filters.set_profile_current_filters(user, %{student_id: student.id})

      {:ok, view, _html} = live(conn, @live_view_path)

      view
      |> element("button#student-ilp-student-toggle-share-controls-student-ilp-student-ilp")
      |> render_click()

      assert Repo.get(StudentILP, student_ilp.id).is_shared_with_student
      refute Repo.get(StudentILP, student_ilp.id).is_shared_with_guardians

      view
      |> element("button#student-ilp-guardian-toggle-share-controls-student-ilp-student-ilp")
      |> render_click()

      assert Repo.get(StudentILP, student_ilp.id).is_shared_with_student
      assert Repo.get(StudentILP, student_ilp.id).is_shared_with_guardians
    end
  end
end
