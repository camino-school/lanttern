defmodule Lanttern.ILP.ILPCommentAttachment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.ILP.ILPComment

  schema "ilp_comment_attachments" do
    field :position, :integer
    field :link, :string
    field :shared_with_students, :boolean, default: false
    field :is_external, :boolean, default: false

    belongs_to :ilp_comment, ILPComment

    timestamps()
  end

  @doc false
  def changeset(ilp_comment_attachment, attrs) do
    ilp_comment_attachment
    |> cast(attrs, [:link, :position, :shared_with_students, :is_external])
    |> validate_required([:link, :position, :shared_with_students, :is_external])
  end
end
