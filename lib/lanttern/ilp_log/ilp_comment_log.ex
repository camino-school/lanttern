defmodule Lanttern.ILPLog.ILPCommentLog do
  @moduledoc """
  The `ILPCommentLog` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "log"
  schema "ilp_comments" do
    field :ilp_comment_id, :id
    field :profile_id, :id
    field :operation, Ecto.Enum, values: [:CREATE, :UPDATE, :DELETE]

    field :content, :string

    field :student_ilp_id, :id
    field :owner_id, :id

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(ilp_comment_log, attrs) do
    ilp_comment_log
    |> cast(attrs, [
      :ilp_comment_id,
      :profile_id,
      :operation,
      :content,
      :student_ilp_id,
      :owner_id
    ])
    |> validate_required([
      :ilp_comment_id,
      :profile_id,
      :operation,
      :content,
      :student_ilp_id,
      :owner_id
    ])
  end
end
