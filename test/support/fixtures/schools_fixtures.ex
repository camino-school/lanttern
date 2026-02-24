defmodule Lanttern.SchoolsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Schools` context.
  """

  import Lanttern.Factory

  @doc """
  Generate a school.
  """
  def school_fixture(attrs \\ %{}) do
    insert(:school, attrs)
  end

  @doc """
  Generate a cycle.
  """
  def cycle_fixture(attrs \\ %{}) do
    {school_id, attrs} = Map.pop(attrs, :school_id)

    attrs =
      if school_id do
        school = Lanttern.Repo.get!(Lanttern.Schools.School, school_id)
        Map.put(attrs, :school, school)
      else
        attrs
      end

    cycle = insert(:cycle, attrs)
    Lanttern.Repo.get!(Lanttern.Schools.Cycle, cycle.id)
  end

  @doc """
  Generate a class.
  """
  def class_fixture(attrs \\ %{})

  def class_fixture(attrs) when is_list(attrs), do: class_fixture(Map.new(attrs))

  def class_fixture(%{cycle_id: cycle_id} = attrs) do
    school_id = maybe_gen_school_id(attrs)
    current_user = %{current_profile: %{school_id: school_id}}

    {:ok, class} =
      attrs
      |> Enum.into(%{
        cycle_id: cycle_id,
        name: "some class name #{Ecto.UUID.generate()}"
      })
      |> Lanttern.Schools.create_class(current_user)

    class
  end

  def class_fixture(attrs) do
    school_id = maybe_gen_school_id(attrs)
    cycle = cycle_fixture(%{school_id: school_id})
    current_user = %{current_profile: %{school_id: school_id}}

    {:ok, class} =
      attrs
      |> Enum.into(%{
        cycle_id: cycle.id,
        name: "some class name #{Ecto.UUID.generate()}"
      })
      |> Lanttern.Schools.create_class(current_user)

    class
  end

  @doc """
  Generate a student.
  """
  def student_fixture(attrs \\ %{}) do
    {classes_ids, attrs} = Map.pop(attrs, :classes_ids)
    attrs = Map.put_new_lazy(attrs, :school_id, fn -> school_fixture().id end)
    student = insert(:student, attrs)

    if is_list(classes_ids) && length(classes_ids) > 0 do
      student = Lanttern.Repo.preload(student, :classes)
      {:ok, student} = Lanttern.Schools.update_student(student, %{classes_ids: classes_ids})
      student
    else
      student
    end
  end

  @doc """
  Generate a staff member.
  """
  def staff_member_fixture(attrs \\ %{}) do
    email = Map.get(attrs, :email) || Map.get(attrs, "email")

    if is_binary(email) && email != "" do
      # When email is provided, use context to properly create profile/user association
      attrs =
        attrs
        |> Map.put_new_lazy(:school_id, fn -> school_fixture().id end)
        |> Map.put_new(:name, "Staff Member")
        |> Map.put_new(:role, "Teacher")

      {:ok, staff_member} = Lanttern.Schools.create_staff_member(attrs)
      staff_member
    else
      {school_id, attrs} = Map.pop(attrs, :school_id)

      attrs =
        if school_id do
          school = Lanttern.Repo.get!(Lanttern.Schools.School, school_id)
          Map.put(attrs, :school, school)
        else
          attrs
        end

      staff_member = insert(:staff_member, attrs)
      Lanttern.Repo.get!(Lanttern.Schools.StaffMember, staff_member.id)
    end
  end

  @doc """
  Generate a class staff member relationship.
  """
  def class_staff_member_fixture(attrs \\ %{}) do
    {class_id, attrs} = Map.pop(attrs, :class_id)
    {staff_member_id, attrs} = Map.pop(attrs, :staff_member_id)

    attrs =
      case {class_id, staff_member_id} do
        {nil, nil} ->
          attrs

        {nil, smid} ->
          staff_member = Lanttern.Repo.get!(Lanttern.Schools.StaffMember, smid)
          class = class_fixture(%{school_id: staff_member.school_id})
          attrs |> Map.put(:class, class) |> Map.put(:staff_member, staff_member)

        {cid, nil} ->
          class = Lanttern.Repo.get!(Lanttern.Schools.Class, cid)
          staff_member = staff_member_fixture(%{school_id: class.school_id})
          attrs |> Map.put(:class, class) |> Map.put(:staff_member, staff_member)

        {cid, smid} ->
          class = Lanttern.Repo.get!(Lanttern.Schools.Class, cid)
          staff_member = Lanttern.Repo.get!(Lanttern.Schools.StaffMember, smid)
          attrs |> Map.put(:class, class) |> Map.put(:staff_member, staff_member)
      end

    insert(:class_staff_member, attrs)
  end

  # generator helpers

  def maybe_gen_school_id(%{school_id: school_id} = _attrs), do: school_id
  def maybe_gen_school_id(_attrs), do: school_fixture().id

  def maybe_gen_cycle_id(%{cycle_id: cycle_id} = _attrs), do: cycle_id
  def maybe_gen_cycle_id(_attrs), do: cycle_fixture().id

  def maybe_gen_class_id(%{class_id: class_id} = _attrs), do: class_id
  def maybe_gen_class_id(_attrs), do: class_fixture().id

  def maybe_gen_student_id(%{student_id: student_id} = _attrs), do: student_id
  def maybe_gen_student_id(_attrs), do: student_fixture().id

  def maybe_gen_staff_member_id(%{staff_member_id: staff_member_id} = _attrs),
    do: staff_member_id

  def maybe_gen_staff_member_id(_attrs), do: staff_member_fixture().id
end
