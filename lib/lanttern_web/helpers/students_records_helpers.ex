defmodule LantternWeb.StudentsRecordsHelpers do
  @moduledoc """
  Helper functions related to `StudentsRecords` context
  """

  alias Lanttern.StudentsRecords

  @doc """
  Generate list of types to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_student_record_type_options()
      [{"type name", 1}, ...]
  """
  def generate_student_record_type_options(opts \\ []) do
    StudentsRecords.list_student_record_types(opts)
    |> Enum.map(fn srt -> {srt.name, srt.id} end)
  end

  @doc """
  Generate list of statuses to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_student_record_status_options()
      [{"status name", 1}, ...]
  """
  def generate_student_record_status_options(opts \\ []) do
    StudentsRecords.list_student_record_statuses(opts)
    |> Enum.map(fn srt -> {srt.name, srt.id} end)
  end
end
