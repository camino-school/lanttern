defmodule LantternWeb.SchoolsHelpers do
  alias Lanttern.Schools

  @doc """
  Generate list of students to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_student_options()
      ["student name": 1, ...]
  """
  def generate_student_options() do
    Schools.list_students()
    |> Enum.map(fn s -> ["#{s.name}": s.id] end)
    |> Enum.concat()
  end

  @doc """
  Generate list of classes to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_class_options()
      ["class name": 1, ...]
  """
  def generate_class_options() do
    Schools.list_classes()
    |> Enum.map(fn s -> ["#{s.name}": s.id] end)
    |> Enum.concat()
  end
end
