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
    end
  end

  setup tags do
    Lanttern.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_teacher

  It stores an updated connection and a registered user and teacher in the test context.
  """
  def register_and_log_in_teacher(%{conn: conn} = context) do
    # use existing context user. useful to register a teacher root admin
    user =
      case context do
        %{user: user} -> user
        _ -> Lanttern.IdentityFixtures.user_fixture()
      end

    # logged in users should always have a current_profile
    teacher = Lanttern.SchoolsFixtures.teacher_fixture()

    profile =
      Lanttern.IdentityFixtures.teacher_profile_fixture(%{
        user_id: user.id,
        teacher_id: teacher.id
      })

    Lanttern.Identity.update_user_current_profile_id(user, profile.id)

    # emulate Identity.get_user_by_session_token/1 to preload profile into user
    user =
      Lanttern.Identity.get_user!(user.id)
      |> Lanttern.Repo.preload(current_profile: [teacher: :school])
      |> Map.update!(:current_profile, fn profile ->
        %Lanttern.Identity.Profile{
          id: profile.id,
          name: profile.teacher.name,
          type: "teacher",
          school_id: profile.teacher.school.id,
          school_name: profile.teacher.school.name
        }
      end)

    %{conn: log_in_user(conn, user), user: user, teacher: teacher}
  end

  @doc """
  Setup helper that registers and logs in students.

      setup :register_and_log_in_student

  It stores an updated connection and registered user and student in the test context.
  """
  def register_and_log_in_student(%{conn: conn}) do
    user = Lanttern.IdentityFixtures.user_fixture()

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
          id: profile.id,
          name: profile.student.name,
          type: "student",
          school_id: profile.student.school.id,
          school_name: profile.student.school.name
        }
      end)

    %{conn: log_in_user(conn, user), user: user, student: student}
  end

  @doc """
  Setup helper that registers and logs in guardians.

      setup :register_and_log_in_guardian

  It stores an updated connection and registered user and student in the test context.
  """
  def register_and_log_in_guardian(%{conn: conn}) do
    user = Lanttern.IdentityFixtures.user_fixture()

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
          id: profile.id,
          name: profile.guardian_of_student.name,
          type: "guardian",
          school_id: profile.guardian_of_student.school.id,
          school_name: profile.guardian_of_student.school.name
        }
      end)

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
end
