defmodule LantternWeb.CommentControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.ConversationFixtures

  @update_attrs %{comment: "some updated comment"}
  @invalid_attrs %{comment: nil}

  setup :register_and_log_in_root_admin

  describe "index" do
    test "lists all comments", %{conn: conn} do
      conn = get(conn, ~p"/admin/comments")
      assert html_response(conn, 200) =~ "Listing Comments"
    end
  end

  describe "new comment" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/comments/new")
      assert html_response(conn, 200) =~ "New Comment"
    end
  end

  describe "create comment" do
    test "redirects to show when data is valid", %{conn: conn} do
      profile = Lanttern.IdentityFixtures.student_profile_fixture()
      create_attrs = %{comment: "some comment", profile_id: profile.id}
      conn = post(conn, ~p"/admin/comments", comment: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/comments/#{id}"

      conn = get(conn, ~p"/admin/comments/#{id}")
      assert html_response(conn, 200) =~ "Comment #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/comments", comment: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Comment"
    end
  end

  describe "edit comment" do
    setup [:create_comment]

    test "renders form for editing chosen comment", %{conn: conn, comment: comment} do
      conn = get(conn, ~p"/admin/comments/#{comment}/edit")
      assert html_response(conn, 200) =~ "Edit Comment"
    end
  end

  describe "update comment" do
    setup [:create_comment]

    test "redirects when data is valid", %{conn: conn, comment: comment} do
      conn = put(conn, ~p"/admin/comments/#{comment}", comment: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/comments/#{comment}"

      conn = get(conn, ~p"/admin/comments/#{comment}")
      assert html_response(conn, 200) =~ "some updated comment"
    end

    test "renders errors when data is invalid", %{conn: conn, comment: comment} do
      conn = put(conn, ~p"/admin/comments/#{comment}", comment: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Comment"
    end
  end

  describe "delete comment" do
    setup [:create_comment]

    test "deletes chosen comment", %{conn: conn, comment: comment} do
      conn = delete(conn, ~p"/admin/comments/#{comment}")
      assert redirected_to(conn) == ~p"/admin/comments"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/comments/#{comment}")
      end
    end
  end

  defp create_comment(_) do
    comment = comment_fixture()
    %{comment: comment}
  end
end
