defmodule Lanttern.LearningContext.StarredStrand do
  @moduledoc """
  The `StarredStrand` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "starred_strands" do
    field :strand_id, :id, primary_key: true
    field :profile_id, :id, primary_key: true
  end

  @doc false
  def changeset(starred_strand, attrs) do
    starred_strand
    |> cast(attrs, [:strand_id, :profile_id])
    |> validate_required([:strand_id, :profile_id])
  end
end
