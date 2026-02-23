defmodule Lanttern.SchemaHelpers do
  @moduledoc """
  Schema related helpers
  """

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Lanttern.Repo
  alias Lanttern.Taxonomy

  @doc """
  `put_assoc` subjects in a changeset.

  It expects `subjects_ids` (virtual `{:array, :id}` field) to be cast in the changeset.
  """
  def put_subjects(changeset) do
    put_subjects(
      changeset,
      get_change(changeset, :subjects_ids)
    )
  end

  defp put_subjects(changeset, nil), do: changeset

  defp put_subjects(changeset, subjects_ids) do
    subjects =
      from(s in Taxonomy.Subject, where: s.id in ^subjects_ids)
      |> Repo.all()

    changeset
    |> put_assoc(:subjects, subjects)
  end

  @doc """
  `put_assoc` years in a changeset.

  It expects `years_ids` (virtual `{:array, :id}` field) to be cast in the changeset.
  """
  def put_years(changeset) do
    put_years(
      changeset,
      get_change(changeset, :years_ids)
    )
  end

  defp put_years(changeset, nil), do: changeset

  defp put_years(changeset, years_ids) do
    years =
      from(y in Taxonomy.Year, where: y.id in ^years_ids)
      |> Repo.all()

    changeset
    |> put_assoc(:years, years)
  end

  @doc """
  Validates a hex color field and optionally adds a `check_constraint`.

  When `constraint_name` is provided, both a `validate_format` and a
  `check_constraint` are applied. Otherwise only the format validation
  is added.

  ## Examples

      changeset
      |> validate_hex_color(:bg_color, :school_bg_color_should_be_hex)

      changeset
      |> validate_hex_color(:bg_color)

  """
  def validate_hex_color(changeset, field, constraint_name \\ nil)

  def validate_hex_color(changeset, field, nil) do
    validate_format(changeset, field, ~r/^#[a-fA-F0-9]{6}$/,
      message: "must be a valid hex color (e.g. #aabbcc)"
    )
  end

  def validate_hex_color(changeset, field, constraint_name) do
    changeset
    |> validate_format(field, ~r/^#[a-fA-F0-9]{6}$/,
      message: "must be a valid hex color (e.g. #aabbcc)"
    )
    |> check_constraint(field,
      name: constraint_name,
      message: "must be a valid hex color (e.g. #aabbcc)"
    )
  end

  @doc """
  Set `:position` in child changeset.

  Example:

      changeset
      |> cast_assoc(:list_field, with: &child_changeset/3)

  """
  def child_position_changeset(child, changes, position) do
    child
    |> change(
      changes
      |> Map.put(:position, position)
    )
  end
end
