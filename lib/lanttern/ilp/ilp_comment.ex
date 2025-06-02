defmodule Lanttern.ILP.ILPComment do
  @moduledoc """
  Schema for ILP Comments
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.Profile
  alias Lanttern.ILP.StudentILP
  alias Lanttern.ILP.ILPCommentAttachment

  schema "ilp_comments" do
    field :position, :integer
    field :content, :string
    field :shared_with_students, :boolean, default: false

    belongs_to :student_ilp, StudentILP
    belongs_to :owner, Profile

    has_many :attachments, ILPCommentAttachment

    timestamps()
  end

  @required ~w(content position shared_with_students student_ilp_id owner_id)a

  @doc false
  def changeset(ilp_comment, attrs) do
    ilp_comment
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
