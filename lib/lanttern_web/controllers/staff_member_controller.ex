defmodule LantternWeb.StaffMemberController do
  use LantternWeb, :controller

  import LantternWeb.SchoolsHelpers
  alias Lanttern.Schools
  alias Lanttern.Schools.StaffMember

  def index(conn, _params) do
    staff_members = Schools.list_staff_members(preloads: :school)
    render(conn, :index, staff_members: staff_members)
  end

  def new(conn, _params) do
    school_options = generate_school_options()
    changeset = Schools.change_staff_member(%StaffMember{})
    render(conn, :new, school_options: school_options, changeset: changeset)
  end

  def create(conn, %{"staff_member" => staff_member_params}) do
    case Schools.create_staff_member(staff_member_params) do
      {:ok, staff_member} ->
        conn
        |> put_flash(:info, "Staff member created successfully.")
        |> redirect(to: ~p"/admin/staff_members/#{staff_member}")

      {:error, %Ecto.Changeset{} = changeset} ->
        school_options = generate_school_options()
        render(conn, :new, school_options: school_options, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    staff_member = Schools.get_staff_member!(id, preloads: :school)
    render(conn, :show, staff_member: staff_member)
  end

  def edit(conn, %{"id" => id}) do
    staff_member = Schools.get_staff_member!(id)
    school_options = generate_school_options()
    changeset = Schools.change_staff_member(staff_member)

    render(conn, :edit,
      staff_member: staff_member,
      school_options: school_options,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "staff_member" => staff_member_params}) do
    staff_member = Schools.get_staff_member!(id)

    case Schools.update_staff_member(staff_member, staff_member_params) do
      {:ok, staff_member} ->
        conn
        |> put_flash(:info, "Staff member updated successfully.")
        |> redirect(to: ~p"/admin/staff_members/#{staff_member}")

      {:error, %Ecto.Changeset{} = changeset} ->
        school_options = generate_school_options()

        render(conn, :edit,
          staff_member: staff_member,
          school_options: school_options,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    staff_member = Schools.get_staff_member!(id)
    {:ok, _staff_member} = Schools.delete_staff_member(staff_member)

    conn
    |> put_flash(:info, "Staff member deleted successfully.")
    |> redirect(to: ~p"/admin/staff_members")
  end
end
