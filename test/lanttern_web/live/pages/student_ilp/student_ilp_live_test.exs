defmodule LantternWeb.StudentILPLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  setup [:register_and_log_in_student]

  describe "Student ILP live view" do
    test "returns ok when create a ILP comments", ctx do
      school = ctx.user.current_profile.student.school
      student = ctx.user.current_profile.student
      insert(:student_ilp, %{school: school, student: student, is_shared_with_student: true})

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

      student_ilp =
        insert(:student_ilp, %{school: school, student: student, is_shared_with_student: true})

      comment1 =
        insert(:ilp_comment, %{student_ilp: student_ilp, owner: ctx.user.current_profile})

      comment2 =
        insert(:ilp_comment, %{
          student_ilp: student_ilp,
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

      student_ilp =
        insert(:student_ilp, %{school: school, student: student, is_shared_with_student: true})

      ilp_comment =
        insert(:ilp_comment, %{student_ilp: student_ilp, owner: ctx.user.current_profile})

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

    test "not renders edition when not owns comment", ctx do
      school = ctx.user.current_profile.student.school
      student = ctx.user.current_profile.student
      new_profile = insert(:profile)

      student_ilp =
        insert(:student_ilp, %{school: school, student: student, is_shared_with_student: true})

      ilp_comment = insert(:ilp_comment, %{student_ilp: student_ilp, owner: new_profile})

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

    test "create and edit ilp comment attachments", ctx do
      school = ctx.user.current_profile.student.school
      student = ctx.user.current_profile.student

      student_ilp =
        insert(:student_ilp, %{school: school, student: student, is_shared_with_student: true})

      ilp_comment =
        insert(:ilp_comment, %{student_ilp: student_ilp, owner: ctx.user.current_profile})

      ctx.conn
      |> visit("/student_ilp?comment_id=#{ilp_comment.id}")
      |> assert_has("p", text: ilp_comment.content)
      |> click_button("#external-link-button", "Or add a link to an external file")
      |> fill_in("Attachment name", with: "News")
      |> fill_in("Link", with: "http://www.science.org/article-1")
      |> submit()

      ctx.conn
      |> visit("/student_ilp/")
      |> assert_has("p", text: ilp_comment.content)
      |> assert_has("a", text: "News")

      ctx.conn
      |> visit("/student_ilp?comment_id=#{ilp_comment.id}")
      |> assert_has("p", text: ilp_comment.content)
      |> click_button("Edit")
      |> fill_in("Attachment name", with: "Article2")
      |> fill_in("Link", with: "http://www.science.org/article-2")
      |> submit()

      ctx.conn
      |> visit("/student_ilp/")
      |> assert_has("p", text: ilp_comment.content)
      |> assert_has("a", text: "Article2")
      |> refute_has("a", text: "News")
    end
  end
end
