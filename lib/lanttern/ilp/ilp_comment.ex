defmodule Lanttern.ILP.ILPComment do
  @moduledoc """
  Schema for ILP Comments
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.Profile
  alias Lanttern.ILP.ILPCommentAttachment
  alias Lanttern.ILP.StudentILP

  @type t :: %__MODULE__{
          id: pos_integer(),
          content: String.t(),
          position: pos_integer(),
          student_ilp_id: pos_integer(),
          student_ilp: StudentILP.t(),
          owner_id: pos_integer(),
          owner: Profile.t(),
          attachments: [ILPCommentAttachment.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ilp_comments" do
    field :content, :string
    field :position, :integer

    belongs_to :student_ilp, StudentILP
    belongs_to :owner, Profile

    has_many :attachments, ILPCommentAttachment

    timestamps()
  end

  @doc false
  def changeset(ilp_comment, attrs) do
    ilp_comment
    |> cast(attrs, [:content, :position, :student_ilp_id, :owner_id])
    |> validate_required([:content, :position, :student_ilp_id, :owner_id])
  end
end
