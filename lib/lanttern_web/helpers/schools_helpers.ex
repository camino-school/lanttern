defmodule LantternWeb.SchoolsHelpers do
  alias Lanttern.Schools

  @doc """
  Generate list of schools to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_school_options()
      [{"school name", 1}, ...]
  """
  def generate_school_options() do
    Schools.list_schools()
    |> Enum.map(fn s -> {s.name, s.id} end)
  end

  @doc """
  Generate list of classes to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_class_options()
      [{"class name", 1}, ...]
  """
  def generate_class_options() do
    Schools.list_classes()
    |> Enum.map(fn s -> {s.name, s.id} end)
  end

  @doc """
  Generate list of students to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_student_options()
      [{"student name", 1}, ...]
  """
  def generate_student_options() do
    Schools.list_students()
    |> Enum.map(fn s -> {s.name, s.id} end)
  end

  @doc """
  Generate list of teachers to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_teacher_options()
      [{"teacher name", 1}, ...]
  """
  def generate_teacher_options() do
    Schools.list_teachers()
    |> Enum.map(fn t -> {t.name, t.id} end)
  end
end
