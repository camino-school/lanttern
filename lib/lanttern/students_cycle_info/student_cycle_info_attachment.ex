defmodule Lanttern.StudentsCycleInfo.StudentCycleInfoAttachment do
  @moduledoc """
  The `StudentCycleInfoAttachment` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Attachments.Attachment
  alias Lanttern.StudentsCycleInfo.StudentCycleInfo

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          shared_with_student: boolean(),
          student_cycle_info: StudentCycleInfo.t(),
          student_cycle_info_id: pos_integer(),
          attachment: Attachment.t(),
          attachment_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "students_cycle_info_attachments" do
    field :position, :integer, default: 0
    field :shared_with_student, :boolean, default: false

    belongs_to :student_cycle_info, StudentCycleInfo
    belongs_to :attachment, Attachment

    timestamps()
  end

  @doc false
  def changeset(student_cycle_info_attachment, attrs) do
    student_cycle_info_attachment
    |> cast(attrs, [:position, :shared_with_student, :student_cycle_info_id, :attachment_id])
    |> validate_required([
      :position,
      :shared_with_student,
      :student_cycle_info_id,
      :attachment_id
    ])
  end
end
