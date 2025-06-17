defmodule Lanttern.ILP.ILPCommentAttachment do
  @moduledoc """
  Schema for ILP Comment Attachments
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.ILP.ILPComment

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          link: String.t(),
          position: pos_integer(),
          is_external: boolean(),
          ilp_comment_id: pos_integer(),
          ilp_comment: ILPComment.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ilp_comment_attachments" do
    field :name, :string
    field :position, :integer, default: 0
    field :link, :string
    field :is_external, :boolean, default: false

    belongs_to :ilp_comment, ILPComment

    timestamps()
  end

  @doc false
  def changeset(ilp_comment_attachment, attrs) do
    ilp_comment_attachment
    |> cast(attrs, [:ilp_comment_id, :name, :link, :position, :is_external])
    |> validate_required([:ilp_comment_id, :name, :link, :position, :is_external])
  end
end
