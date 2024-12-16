defmodule LantternWeb.SchoolsHelpers do
  @moduledoc """
  Helper functions related to `Schools` context
  """

  alias Lanttern.Schools
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.Class
  alias Lanttern.Identity.Profile
  alias Lanttern.Identity.User

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
  Generate list of cycles to use as `Phoenix.HTML.Form.options_for_select/2` arg

  Accepts `list_opts` arg, which will be forwarded to `Schools.list_cycles/1`.

  ## Examples

      iex> generate_cycle_options()
      [{"cycle name", 1}, ...]
  """
  def generate_cycle_options(list_opts \\ []) do
    Schools.list_cycles(list_opts)
    |> Enum.map(fn c -> {c.name, c.id} end)
  end

  @doc """
  Generate list of classes to use as `Phoenix.HTML.Form.options_for_select/2` arg

  Accepts `list_opts` arg, which will be forwarded to `Schools.list_classes/1`.

  ## Examples

      iex> generate_class_options()
      [{"class name", 1}, ...]
  """
  def generate_class_options(list_opts \\ []) do
    Schools.list_classes(list_opts)
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

  @doc """
  Returns the class name in the format `"Class A (Cycle X)"`.

  Only class name will be returned when class cycle is the same as the current cycle
  (infered from `User` or directly from `Cycle` as second argument).

  ## Examples

      iex> class_with_cycle(class)
      "Class A (Cycle X)"
  """
  @spec class_with_cycle(Class.t(), User.t() | Cycle.t() | nil) :: binary()
  def class_with_cycle(class, user \\ nil)

  def class_with_cycle(
        %Class{cycle_id: class_cycle_id} = class,
        %User{
          current_profile: %Profile{current_school_cycle: %Cycle{id: current_cycle_id}}
        }
      )
      when class_cycle_id == current_cycle_id,
      do: class.name

  def class_with_cycle(
        %Class{cycle_id: class_cycle_id} = class,
        %Cycle{id: current_cycle_id}
      )
      when class_cycle_id == current_cycle_id,
      do: class.name

  def class_with_cycle(%Class{cycle: %Cycle{} = cycle} = class, _user),
    do: "#{class.name} (#{cycle.name})"

  def class_with_cycle(%Class{} = class, _user), do: class.name
end
