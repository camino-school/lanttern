defmodule Lanttern.Grading.Scale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grading_scales" do
    field :name, :string
    field :type, :string
    field :start, :float
    field :start_bg_color, :string
    field :start_text_color, :string
    field :stop, :float
    field :stop_bg_color, :string
    field :stop_text_color, :string
    field :breakpoints, {:array, :float}

    has_many :ordinal_values, Lanttern.Grading.OrdinalValue

    timestamps()
  end

  @doc false
  def changeset(scale, attrs) do
    scale
    |> cast(attrs, [
      :name,
      :type,
      :start,
      :start_bg_color,
      :start_text_color,
      :stop,
      :stop_bg_color,
      :stop_text_color,
      :breakpoints
    ])
    |> validate_required([:name, :type])
    |> validate_scale_type()
    |> validate_start_stop()
    |> adjust_breakpoints()
    |> check_constraint(:start_bg_color,
      name: :scale_start_bg_color_should_be_hex,
      message: "Invalid hex color"
    )
    |> check_constraint(:start_text_color,
      name: :scale_start_text_color_should_be_hex,
      message: "Invalid hex color"
    )
    |> check_constraint(:stop_bg_color,
      name: :scale_stop_bg_color_should_be_hex,
      message: "Invalid hex color"
    )
    |> check_constraint(:stop_text_color,
      name: :scale_stop_text_color_should_be_hex,
      message: "Invalid hex color"
    )
    |> check_constraint(:breakpoints,
      name: :breakpoints_should_be_between_0_and_1,
      message: "Values in breakpoint should be greater than 0 and less than 1"
    )
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

  # Order values and remove duplicates from `:breakpoints`
  defp adjust_breakpoints(changeset) do
    changeset
    |> update_change(:breakpoints, fn breakpoints ->
      breakpoints
      |> Enum.sort()
      |> Enum.uniq()
    end)
  end
end
