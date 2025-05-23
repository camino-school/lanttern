defmodule LantternWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use LantternWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint LantternWeb.Endpoint

      use LantternWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import LantternWeb.ConnCase
      import Lanttern.Support.TestUtils
    end
  end

  setup tags do
    Lanttern.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_staff_member

  It stores an updated connection and a registered user and staff member in the test context.
  """
  def register_and_log_in_staff_member(%{conn: conn} = context) do
    # use existing context user. useful to register a staff member root admin
    user =
      case context do
        %{user: user} -> user
        _ -> Lanttern.IdentityFixtures.user_fixture()
      end

    # "accept" privacy policy
    {:ok, user} = Lanttern.Identity.update_user_privacy_policy_accepted(user, "some meta")

    # logged in users should always have a current_profile
    staff_member = Lanttern.SchoolsFixtures.staff_member_fixture()

    profile =
      Lanttern.IdentityFixtures.staff_member_profile_fixture(%{
        user_id: user.id,
        staff_member_id: staff_member.id
      })

    Lanttern.Identity.update_user_current_profile_id(user, profile.id)

    # emulate Identity.get_user_by_session_token/1 to preload profile into user
    user =
      Lanttern.Identity.get_user!(user.id)
      |> Lanttern.Repo.preload(current_profile: [staff_member: :school])
      |> Map.update!(:current_profile, fn profile ->
        %Lanttern.Identity.Profile{
          profile
          | name: profile.staff_member.name,
            school_id: profile.staff_member.school.id,
            school_name: profile.staff_member.school.name,
            role: profile.staff_member.role,
            profile_picture_url: profile.staff_member.profile_picture_url
        }
      end)
      # profile should always have a current school cycle
      |> inject_current_school_cycle()

    %{conn: log_in_user(conn, user), user: user, staff_member: staff_member}
  end

  @doc """
  Setup helper that registers and logs in students.

      setup :register_and_log_in_student

  It stores an updated connection and registered user and student in the test context.
  """
  def register_and_log_in_student(%{conn: conn}) do
    user = Lanttern.IdentityFixtures.user_fixture()

    # "accept" privacy policy
    {:ok, user} = Lanttern.Identity.update_user_privacy_policy_accepted(user, "some meta")

    # logged in users should always have a current_profile
    student = Lanttern.SchoolsFixtures.student_fixture()

    profile =
      Lanttern.IdentityFixtures.student_profile_fixture(%{student_id: student.id})

    Lanttern.Identity.update_user_current_profile_id(user, profile.id)

    # emulate Identity.get_user_by_session_token/1 to preload profile into user
    user =
      Lanttern.Identity.get_user!(user.id)
      |> Lanttern.Repo.preload(current_profile: [student: :school])
      |> Map.update!(:current_profile, fn profile ->
        %Lanttern.Identity.Profile{
          profile
          | name: profile.student.name,
            school_id: profile.student.school.id,
            school_name: profile.student.school.name
        }
      end)
      # profile should always have a current school cycle
      |> inject_current_school_cycle()

    %{conn: log_in_user(conn, user), user: user, student: student}
  end

  @doc """
  Setup helper that registers and logs in guardians.

      setup :register_and_log_in_guardian

  It stores an updated connection and registered user and student in the test context.
  """
  def register_and_log_in_guardian(%{conn: conn}) do
    user = Lanttern.IdentityFixtures.user_fixture()

    # "accept" privacy policy
    {:ok, user} = Lanttern.Identity.update_user_privacy_policy_accepted(user, "some meta")

    # logged in users should always have a current_profile
    student = Lanttern.SchoolsFixtures.student_fixture()

    profile =
      Lanttern.IdentityFixtures.guardian_profile_fixture(%{guardian_of_student_id: student.id})

    Lanttern.Identity.update_user_current_profile_id(user, profile.id)

    # emulate Identity.get_user_by_session_token/1 to preload profile into user
    user =
      Lanttern.Identity.get_user!(user.id)
      |> Lanttern.Repo.preload(current_profile: [guardian_of_student: :school])
      |> Map.update!(:current_profile, fn profile ->
        %Lanttern.Identity.Profile{
          profile
          | name: profile.guardian_of_student.name,
            school_id: profile.guardian_of_student.school.id,
            school_name: profile.guardian_of_student.school.name
        }
      end)
      # profile should always have a current school cycle
      |> inject_current_school_cycle()

    %{conn: log_in_user(conn, user), user: user, student: student}
  end

  @doc """
  Setup helper that registers and logs in root admin.

      setup :register_and_log_in_root_admin

  It stores an updated connection and a registered root
  admin user in the test context.
  """
  def register_and_log_in_root_admin(%{conn: conn}) do
    root_admin = Lanttern.IdentityFixtures.root_admin_fixture()
    %{conn: log_in_user(conn, root_admin), user: root_admin}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = Lanttern.Identity.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  @doc """
  Setup helper that adds permissions to current user profile.
  """
  def set_user_permissions(permissions, %{conn: conn, user: user}) do
    {:ok, settings} =
      Lanttern.Personalization.set_profile_settings(user.current_profile_id, %{
        permissions: permissions
      })

    emulate_profile_preload(conn, user, settings)
  end

  defp emulate_profile_preload(conn, user, settings) do
    # emulate Identity.get_user_by_session_token/1 to preload profile into user
    user =
      user
      |> Map.update!(:current_profile, &%{&1 | permissions: settings.permissions})

    %{conn: log_in_user(conn, user), user: user}
  end

  # helpers

  defp inject_current_school_cycle(user) do
    school_id = user.current_profile.school_id

    cycle =
      Lanttern.SchoolsFixtures.cycle_fixture(%{
        school_id: school_id,
        start_at: ~D[2020-01-01],
        end_at: ~D[2020-12-31]
      })

    user
    |> Map.update!(:current_profile, fn profile ->
      %{profile | current_school_cycle: cycle}
    end)
  end
end
