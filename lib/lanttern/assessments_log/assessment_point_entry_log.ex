defmodule Lanttern.AssessmentsLog.AssessmentPointEntryLog do
  @moduledoc """
  The `AssessmentPointEntryLog` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "log"
  schema "assessment_point_entries" do
    field :assessment_point_entry_id, :integer
    field :profile_id, :integer
    field :operation, :string
    field :observation, :string
    field :score, :float
    field :student_score, :float
    field :assessment_point_id, :integer
    field :student_id, :integer
    field :ordinal_value_id, :integer
    field :student_ordinal_value_id, :integer
    field :scale_id, :integer
    field :scale_type, :string
    field :differentiation_rubric_id, :integer
    field :report_note, :string
    field :student_report_note, :string

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(assessment_point_entry_log, attrs) do
    assessment_point_entry_log
    |> cast(attrs, [
      :assessment_point_entry_id,
      :profile_id,
      :operation,
      :observation,
      :score,
      :student_score,
      :assessment_point_id,
      :student_id,
      :ordinal_value_id,
      :student_ordinal_value_id,
      :scale_id,
      :scale_type,
      :differentiation_rubric_id,
      :report_note,
      :student_report_note
    ])
    |> validate_required([
      :assessment_point_entry_id,
      :profile_id,
      :operation,
      :assessment_point_id,
      :student_id,
      :scale_id,
      :scale_type
    ])
  end
end
