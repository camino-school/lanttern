defmodule Lanttern.Grading.Scale do
  @moduledoc """
  The `Scale` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext
  import Lanttern.SchemaHelpers, only: [validate_hex_color: 3]

  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Identity.Scope
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          type: String.t(),
          position: non_neg_integer(),
          start: float(),
          start_bg_color: String.t(),
          start_text_color: String.t(),
          stop: float(),
          stop_bg_color: String.t(),
          stop_text_color: String.t(),
          breakpoints: [float()],
          breakpoints_input: String.t() | nil,
          ordinal_values: [OrdinalValue.t()],
          school_id: pos_integer(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t(),
          deactivated_at: DateTime.t() | nil
        }

  schema "grading_scales" do
    field :name, :string
    field :type, :string
    field :position, :integer, default: 0
    field :start, :float
    field :start_bg_color, :string
    field :start_text_color, :string
    field :stop, :float
    field :stop_bg_color, :string
    field :stop_text_color, :string
    field :breakpoints, {:array, :float}
    field :breakpoints_input, :string, virtual: true
    field :deactivated_at, :utc_datetime

    has_many :ordinal_values, OrdinalValue, preload_order: [asc: :normalized_value, asc: :name]
    belongs_to :school, Lanttern.Schools.School

    timestamps()
  end

  @doc false
  def changeset(scale, attrs, %Scope{} = scope) do
    scale
    |> cast(attrs, [
      :name,
      :type,
      :position,
      :start,
      :start_bg_color,
      :start_text_color,
      :stop,
      :stop_bg_color,
      :stop_text_color,
      :breakpoints,
      :breakpoints_input
    ])
    |> validate_required([:name, :type])
    |> put_change(:school_id, scope.school_id)
    |> validate_scale_type()
    |> validate_start_stop()
    |> parse_breakpoints_input()
    |> adjust_breakpoints()
    |> validate_hex_color(:start_bg_color, :scale_start_bg_color_should_be_hex)
    |> validate_hex_color(:start_text_color, :scale_start_text_color_should_be_hex)
    |> validate_hex_color(:stop_bg_color, :scale_stop_bg_color_should_be_hex)
    |> validate_hex_color(:stop_text_color, :scale_stop_text_color_should_be_hex)
    |> check_constraint(:breakpoints,
      name: :breakpoints_should_be_between_0_and_1,
      message: "Values in breakpoint should be greater than 0 and less than 1"
    )
  end

  def activate_changeset(scale) do
    scale
    |> cast(%{}, [])
    |> put_change(:deactivated_at, nil)
  end

  def deactivate_changeset(scale) do
    scale
    |> cast(%{}, [])
    |> put_change(:deactivated_at, DateTime.utc_now(:second))
  end

  def delete_changeset(scale) do
    scale
    |> cast(%{}, [])
    |> foreign_key_constraint(
      :id,
      name: :assessment_point_entries_scale_id_fkey,
      message: gettext("This scale is being used and cannot be deleted")
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

  defp parse_breakpoints_input(changeset) do
    case get_change(changeset, :breakpoints_input) do
      nil ->
        changeset

      input ->
        input
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.reduce_while([], &float_parse/2)
        |> handle_float_parse_result(changeset)
    end
  end

  defp float_parse(str, acc) do
    case Float.parse(str) do
      {val, ""} when val > 0 and val < 1 -> {:cont, [val | acc]}
      {_val, ""} -> {:halt, :out_of_range}
      _ -> {:halt, :error}
    end
  end

  defp handle_float_parse_result(:error, changeset) do
    add_error(
      changeset,
      :breakpoints_input,
      gettext("must be a list of numbers separated by commas")
    )
  end

  defp handle_float_parse_result(:out_of_range, changeset) do
    add_error(
      changeset,
      :breakpoints_input,
      gettext("each value must be greater than 0 and less than 1")
    )
  end

  defp handle_float_parse_result(floats, changeset) do
    put_change(changeset, :breakpoints, Enum.reverse(floats))
  end

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
