defmodule Lanttern.LearningContext.StrandLog do
  @moduledoc """
  The `StrandLog` schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Lanttern.AuditLog

  @schema_prefix "log"
  schema "strands" do
    field :strand_id, :integer
    field :profile_id, :integer
    field :operation, :string
    field :name, :string
    field :type, :string
    field :description, :string
    field :assessment_info, :string
    field :teacher_instructions, :string
    field :cover_image_url, :string
    field :is_locked, :boolean, default: false
    field :subjects_ids, {:array, :integer}
    field :years_ids, {:array, :integer}

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(strand_log, attrs) do
    strand_log
    |> cast(attrs, [
      :strand_id,
      :profile_id,
      :operation,
      :name,
      :type,
      :description,
      :assessment_info,
      :teacher_instructions,
      :cover_image_url,
      :is_locked,
      :subjects_ids,
      :years_ids
    ])
    |> validate_required([
      :strand_id,
      :profile_id,
      :operation,
      :name
    ])
  end

  @impl Lanttern.AuditLog
  def build_log_attrs(%Lanttern.LearningContext.Strand{} = strand) do
    strand = Lanttern.Repo.preload(strand, [:subjects, :years])

    %{
      strand_id: strand.id,
      name: strand.name,
      type: strand.type,
      description: strand.description,
      assessment_info: strand.assessment_info,
      teacher_instructions: strand.teacher_instructions,
      cover_image_url: strand.cover_image_url,
      is_locked: strand.is_locked,
      subjects_ids: Enum.map(strand.subjects, & &1.id),
      years_ids: Enum.map(strand.years, & &1.id)
    }
  end
end
