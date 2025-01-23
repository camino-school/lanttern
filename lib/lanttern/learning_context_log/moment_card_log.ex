defmodule Lanttern.LearningContextLog.MomentCardLog do
  @moduledoc """
  The `MomentCardLog` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "log"
  schema "moment_cards" do
    field :moment_card_id, :id
    field :profile_id, :id
    field :operation, :string

    field :moment_id, :id

    field :name, :string
    field :position, :integer
    field :description, :string
    field :teacher_instructions, :string
    field :differentiation, :string
    field :shared_with_students, :boolean

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(student_cycle_info_log, attrs) do
    student_cycle_info_log
    |> cast(attrs, [
      :moment_card_id,
      :profile_id,
      :operation,
      :moment_id,
      :name,
      :position,
      :description,
      :teacher_instructions,
      :differentiation,
      :shared_with_students
    ])
    |> validate_required([
      :moment_card_id,
      :profile_id,
      :operation,
      :moment_id,
      :name,
      :position,
      :description,
      :shared_with_students
    ])
  end
end
