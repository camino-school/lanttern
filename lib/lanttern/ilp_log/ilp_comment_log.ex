defmodule Lanttern.ILPLog.ILPCommentLog do
  @moduledoc """
  The `ILPCommentLog` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "log"
  schema "ilp_comments" do
    field :ilp_comment_id, :id
    field :owner_id, :id
    field :student_ilp_id, :id
    field :operation, Ecto.Enum, values: [:CREATE, :UPDATE, :DELETE]

    field :position, :integer
    field :content, :string

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(ilp_comment_log, attrs) do
    ilp_comment_log
    |> cast(attrs, [
      :ilp_comment_id,
      :owner_id,
      :student_ilp_id,
      :operation,
      :position,
      :content
    ])
    |> validate_required([
      :ilp_comment_id,
      :owner_id,
      :student_ilp_id,
      :operation,
      :position,
      :content
    ])
  end
end
