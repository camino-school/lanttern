defmodule Lanttern.Grading.Scale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grading_scales" do
    field :name, :string
    field :start, :float
    field :stop, :float
    field :type, :string

    has_many :ordinal_values, Lanttern.Grading.OrdinalValue

    timestamps()
  end

  @doc false
  def changeset(scale, attrs) do
    scale
    |> cast(attrs, [:name, :type, :start, :stop])
    |> validate_required([:name, :type])
    |> validate_scale_type()
    |> validate_start_stop()
  end

  @valid_types ["numeric", "ordinal"]
  defp validate_scale_type(changeset) do
    changeset
    |> validate_change(:type, fn :type, type ->
      if type in @valid_types do
        []
      else
        [type: ~s(must be "numeric" or "ordinal")]
      end
    end)
  end

  defp validate_start_stop(%{changes: %{type: "numeric"}} = changeset) do
    changeset
    |> validate_required([:start, :stop], message: "can't be blank when type is numeric")
  end

  defp validate_start_stop(changeset), do: changeset
end
