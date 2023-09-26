defmodule LantternWeb.FeedbackControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.AssessmentsFixtures

  @update_attrs %{comment: "some updated comment"}
  @invalid_attrs %{comment: nil}

  setup :register_and_log_in_root_admin

  describe "index" do
    test "lists all feedback", %{conn: conn} do
      conn = get(conn, ~p"/admin/feedback")
      assert html_response(conn, 200) =~ "Listing Feedback"
    end
  end

  describe "new feedback" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/feedback/new")
      assert html_response(conn, 200) =~ "New Feedback"
    end
  end

  describe "create feedback" do
    test "redirects to show when data is valid", %{conn: conn} do
      assessment_point = assessment_point_fixture()
      student = Lanttern.SchoolsFixtures.student_fixture()
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      create_attrs = %{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        profile_id: profile.id,
        comment: "some comment"
      }

      conn = post(conn, ~p"/admin/feedback", feedback: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/feedback/#{id}"

      conn = get(conn, ~p"/admin/feedback/#{id}")
      assert html_response(conn, 200) =~ "Feedback #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/feedback", feedback: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Feedback"
    end
  end

  describe "edit feedback" do
    setup [:create_feedback]

    test "renders form for editing chosen feedback", %{conn: conn, feedback: feedback} do
      conn = get(conn, ~p"/admin/feedback/#{feedback}/edit")
      assert html_response(conn, 200) =~ "Edit Feedback"
    end
  end

  describe "update feedback" do
    setup [:create_feedback]

    test "redirects when data is valid", %{conn: conn, feedback: feedback} do
      conn = put(conn, ~p"/admin/feedback/#{feedback}", feedback: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/feedback/#{feedback}"

      conn = get(conn, ~p"/admin/feedback/#{feedback}")
      assert html_response(conn, 200) =~ "some updated comment"
    end

    test "renders errors when data is invalid", %{conn: conn, feedback: feedback} do
      conn = put(conn, ~p"/admin/feedback/#{feedback}", feedback: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Feedback"
    end
  end

  describe "delete feedback" do
    setup [:create_feedback]

    test "deletes chosen feedback", %{conn: conn, feedback: feedback} do
      conn = delete(conn, ~p"/admin/feedback/#{feedback}")
      assert redirected_to(conn) == ~p"/admin/feedback"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/feedback/#{feedback}")
      end
    end
  end

  defp create_feedback(_) do
    feedback = feedback_fixture()
    %{feedback: feedback}
  end
end
