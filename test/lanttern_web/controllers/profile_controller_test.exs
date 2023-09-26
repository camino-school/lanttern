defmodule LantternWeb.ProfileControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.IdentityFixtures
  alias Lanttern.SchoolsFixtures

  @invalid_attrs %{type: nil}

  setup :register_and_log_in_root_admin

  describe "index" do
    test "lists all profiles", %{conn: conn} do
      conn = get(conn, ~p"/admin/profiles")
      assert html_response(conn, 200) =~ "Listing Profiles"
    end
  end

  describe "new profile" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/profiles/new")
      assert html_response(conn, 200) =~ "New Profile"
    end
  end

  describe "create profile" do
    test "redirects to show when data is valid", %{conn: conn} do
      user = user_fixture()
      teacher = SchoolsFixtures.teacher_fixture()

      create_attrs = %{
        type: "teacher",
        user_id: user.id,
        teacher_id: teacher.id
      }

      conn = post(conn, ~p"/admin/profiles", profile: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/profiles/#{id}"

      conn = get(conn, ~p"/admin/profiles/#{id}")
      assert html_response(conn, 200) =~ "Profile #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/profiles", profile: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Profile"
    end
  end

  describe "edit profile" do
    setup [:create_profile]

    test "renders form for editing chosen profile", %{conn: conn, profile: profile} do
      conn = get(conn, ~p"/admin/profiles/#{profile}/edit")
      assert html_response(conn, 200) =~ "Edit Profile"
    end
  end

  describe "update profile" do
    setup [:create_profile]

    test "redirects when data is valid", %{conn: conn, profile: profile} do
      student = SchoolsFixtures.student_fixture()
      update_attrs = %{student_id: student.id}
      conn = put(conn, ~p"/admin/profiles/#{profile}", profile: update_attrs)
      assert redirected_to(conn) == ~p"/admin/profiles/#{profile}"

      conn = get(conn, ~p"/admin/profiles/#{profile}")
      assert html_response(conn, 200) =~ student.name
    end

    test "renders errors when data is invalid", %{conn: conn, profile: profile} do
      conn = put(conn, ~p"/admin/profiles/#{profile}", profile: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Profile"
    end
  end

  describe "delete profile" do
    setup [:create_profile]

    test "deletes chosen profile", %{conn: conn, profile: profile} do
      conn = delete(conn, ~p"/admin/profiles/#{profile}")
      assert redirected_to(conn) == ~p"/admin/profiles"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/profiles/#{profile}")
      end
    end
  end

  defp create_profile(_) do
    profile = student_profile_fixture()
    %{profile: profile}
  end
end
