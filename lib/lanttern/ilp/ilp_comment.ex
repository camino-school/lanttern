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
          student_ilp_id: pos_integer(),
          student_ilp: StudentILP.t(),
          owner_id: pos_integer(),
          owner: Profile.t(),
          ilp_comment_attachments: [ILPCommentAttachment.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ilp_comments" do
    field :content, :string

    belongs_to :student_ilp, StudentILP
    belongs_to :owner, Profile

    has_many :ilp_comment_attachments, ILPCommentAttachment, preload_order: [asc: :position]

    timestamps()
  end

  @doc false
  def changeset(ilp_comment, attrs) do
    ilp_comment
    |> cast(attrs, [:content, :student_ilp_id, :owner_id])
    |> validate_required([:content, :student_ilp_id, :owner_id])
  end
end
