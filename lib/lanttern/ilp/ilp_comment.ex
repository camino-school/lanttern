defmodule Lanttern.ILP.ILPComment do
  @moduledoc """
  Schema for ILP Comments
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.ILP.StudentILP
  alias Lanttern.Identity.Profile

  schema "ilp_comments" do
    field :name, :string
    field :position, :integer
    field :content, :string
    field :shared_with_students, :boolean, default: false

    belongs_to :student_ilp, StudentILP
    belongs_to :owner, Profile

    timestamps()
  end

  @required ~w(name content position shared_with_students student_ilp_id owner_id)a

  @doc false
  def changeset(ilp_comment, attrs) do
    ilp_comment
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
