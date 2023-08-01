defmodule Lanttern.Grading.Scale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grading_scales" do
    field :name, :string
    field :start, :float
    field :stop, :float
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(scale, attrs) do
    scale
    |> cast(attrs, [:name, :type, :start, :stop])
    |> validate_required([:name, :type])
    |> validate_start_stop()
  end

  defp validate_start_stop(%{changes: %{type: "numeric"}} = changeset) do
    changeset
    |> validate_required([:start, :stop], message: "can't be blank when type is numeric")
  end

  defp validate_start_stop(changeset), do: changeset
end
