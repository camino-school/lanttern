defmodule Lanttern.Assessments.ActivityAssessmentGrid do
  @moduledoc """
  The struct for building the activity assessment grid.

  The assessment point entries list in `students_entries`
  will always have the same length and order as `assessment_points`,
  avoiding the need to preload the curriculum items in entries.
  """

  alias Lanttern.Schools.Student
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Assessments.AssessmentPointEntry

  defstruct assessment_points: [],
            students_entries: []

  @type t :: %__MODULE__{
          assessment_points: [AssessmentPoint.t()],
          students_entries: [{Student.t(), [AssessmentPointEntry.t() | nil]}]
        }
end
