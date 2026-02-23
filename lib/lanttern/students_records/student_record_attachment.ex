defmodule Lanttern.StudentsRecords.StudentRecordAttachment do
  @moduledoc """
  Schema for Student Record Attachments
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Attachments.Attachment
  alias Lanttern.StudentsRecords.StudentRecord

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: pos_integer(),
          attachment_id: pos_integer(),
          attachment: Attachment.t(),
          student_record_id: pos_integer(),
          student_record: StudentRecord.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "students_records_attachments" do
    field :position, :integer, default: 0

    belongs_to :attachment, Attachment
    belongs_to :student_record, StudentRecord

    timestamps()
  end

  @doc false
  def changeset(student_record_attachment, attrs) do
    student_record_attachment
    |> cast(attrs, [:attachment_id, :student_record_id, :position])
    |> validate_required([:attachment_id, :student_record_id])
  end
end
