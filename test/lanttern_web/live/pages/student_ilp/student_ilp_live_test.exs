defmodule LantternWeb.StudentILPLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  setup [:register_and_log_in_student]

  describe "Student ILP live view" do
    test "returns ok when create a ILP comments", ctx do
      school = ctx.user.current_profile.student.school
      student = ctx.user.current_profile.student
      cycle = ctx.user.current_profile.current_school_cycle
      template = insert(:ilp_template, %{school: school})

      insert(:student_ilp, %{
        student: student,
        cycle: cycle,
        template: template,
        school: school,
        is_shared_with_student: true
      })

      ctx.conn
      |> visit("/student_ilp")
      |> click_link("Add ILP comment")
      |> assert_has("h2", text: "New Comment")
      |> fill_in("Content", with: "Content for quartely feedback")
      |> click_button("Save")

      ctx.conn
      |> visit("/student_ilp")
      |> assert_has("p", text: "Content for quartely feedback")
    end

    test "renders ok when list all ILP comment for a student_ilp", ctx do
      school = ctx.user.current_profile.student.school
      student = ctx.user.current_profile.student
      cycle = ctx.user.current_profile.current_school_cycle
      template = insert(:ilp_template, %{school: school})

      ilp =
        insert(:student_ilp, %{
          student: student,
          cycle: cycle,
          template: template,
          school: school,
          is_shared_with_student: true
        })

      comment1 = insert(:ilp_comment, %{student_ilp: ilp, owner: ctx.user.current_profile})

      comment2 =
        insert(:ilp_comment, %{
          student_ilp: ilp,
          content: "Content.",
          owner: ctx.user.current_profile
        })

      ctx.conn
      |> visit("/student_ilp")
      |> assert_has("p", text: comment1.content)
      |> assert_has("p", text: comment2.content)
    end

    test "renders ok when edit a comment", ctx do
      school = ctx.user.current_profile.student.school
      student = ctx.user.current_profile.student
      cycle = ctx.user.current_profile.current_school_cycle
      template = insert(:ilp_template, %{school: school})

      ilp =
        insert(:student_ilp, %{
          student: student,
          cycle: cycle,
          template: template,
          school: school,
          is_shared_with_student: true
        })

      ilp_comment = insert(:ilp_comment, %{student_ilp: ilp, owner: ctx.user.current_profile})

      ctx.conn
      |> visit("/student_ilp")
      |> assert_has("p", text: ilp_comment.content)
      |> visit("/student_ilp?comment_id=#{ilp_comment.id}")
      |> assert_has("h2", text: "Edit")
      |> fill_in("Content", with: "Novo")
      |> click_button("#save-action-ilp-comment", "Save")

      ctx.conn
      |> visit("/student_ilp/")
      |> assert_has("p", text: "Novo")
    end

    test "renders error when modify not owned comment", ctx do
      school = ctx.user.current_profile.student.school
      student = ctx.user.current_profile.student
      cycle = ctx.user.current_profile.current_school_cycle
      template = insert(:ilp_template, %{school: school})
      new_profile = insert(:profile)

      ilp =
        insert(:student_ilp, %{
          student: student,
          cycle: cycle,
          template: template,
          school: school,
          is_shared_with_student: true
        })

      ilp_comment = insert(:ilp_comment, %{student_ilp: ilp, owner: new_profile})

      ctx.conn
      |> visit("/student_ilp")
      |> assert_has("p", text: ilp_comment.content)
      |> visit("/student_ilp?comment_id=#{ilp_comment.id}")
      |> refute_has("h2", text: "Edit")
      |> refute_has("span", text: "Delete")

      ctx.conn
      |> visit("/student_ilp/")
      |> assert_has("p", text: ilp_comment.content)
    end
  end
end
