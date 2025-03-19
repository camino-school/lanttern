defmodule Lanttern.ILPLog.StudentILPLog do
  @moduledoc """
  The `StudentILPLog` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "log"
  schema "students_ilps" do
    field :student_ilp_id, :id
    field :profile_id, :id
    field :operation, :string
    field :notes, :string
    field :teacher_notes, :string
    field :is_shared_with_student, :boolean, default: false
    field :is_shared_with_guardians, :boolean, default: false
    field :template_id, :id
    field :student_id, :id
    field :cycle_id, :id
    field :school_id, :id
    field :update_of_ilp_id, :id

    embeds_many :entries, Entries, primary_key: false do
      field :id, :id
      field :description, :string
      field :component_id, :id
    end

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(student_ilp_log, attrs) do
    student_ilp_log
    |> cast(attrs, [
      :student_ilp_id,
      :profile_id,
      :operation,
      :notes,
      :teacher_notes,
      :is_shared_with_student,
      :is_shared_with_guardians,
      :template_id,
      :student_id,
      :cycle_id,
      :school_id,
      :update_of_ilp_id
    ])
    |> validate_required([
      :student_ilp_id,
      :profile_id,
      :operation,
      :template_id,
      :student_id,
      :cycle_id,
      :school_id
    ])
    # |> maybe_cast_embed()
    |> cast_embed(:entries, with: &entry_changeset/2)
  end

  # defp maybe_cast_embed(changeset) do
  #   if is_list(get_field(changeset, :entries)) do
  #     cast_embed(changeset, :entries, with: &entry_changeset/2)
  #   else
  #     changeset
  #   end
  # end

  defp entry_changeset(entry, attrs) do
    entry
    |> cast(attrs, [:id, :description, :component_id])
    |> validate_required([:id, :component_id])
  end
end
