defmodule LantternWeb.SubjectControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.TaxonomyFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_root_admin

  describe "index" do
    test "lists all subjects", %{conn: conn} do
      conn = get(conn, ~p"/admin/taxonomy/subjects")
      assert html_response(conn, 200) =~ "Listing Subjects"
    end
  end

  describe "new subject" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/taxonomy/subjects/new")
      assert html_response(conn, 200) =~ "New Subject"
    end
  end

  describe "create subject" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/admin/taxonomy/subjects", subject: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/taxonomy/subjects/#{id}"

      conn = get(conn, ~p"/admin/taxonomy/subjects/#{id}")
      assert html_response(conn, 200) =~ "Subject #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/taxonomy/subjects", subject: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Subject"
    end
  end

  describe "edit subject" do
    setup [:create_subject]

    test "renders form for editing chosen subject", %{conn: conn, subject: subject} do
      conn = get(conn, ~p"/admin/taxonomy/subjects/#{subject}/edit")
      assert html_response(conn, 200) =~ "Edit Subject"
    end
  end

  describe "update subject" do
    setup [:create_subject]

    test "redirects when data is valid", %{conn: conn, subject: subject} do
      conn = put(conn, ~p"/admin/taxonomy/subjects/#{subject}", subject: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/taxonomy/subjects/#{subject}"

      conn = get(conn, ~p"/admin/taxonomy/subjects/#{subject}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, subject: subject} do
      conn = put(conn, ~p"/admin/taxonomy/subjects/#{subject}", subject: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Subject"
    end
  end

  describe "delete subject" do
    setup [:create_subject]

    test "deletes chosen subject", %{conn: conn, subject: subject} do
      conn = delete(conn, ~p"/admin/taxonomy/subjects/#{subject}")
      assert redirected_to(conn) == ~p"/admin/taxonomy/subjects"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/taxonomy/subjects/#{subject}")
      end
    end
  end

  defp create_subject(_) do
    subject = subject_fixture()
    %{subject: subject}
  end
end
