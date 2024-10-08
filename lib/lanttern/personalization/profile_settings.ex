defmodule Lanttern.Personalization.ProfileSettings do
  @moduledoc """
  The `ProfileSettings` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

  alias Lanttern.Identity.Profile
  alias Lanttern.Personalization

  @type t :: %__MODULE__{
          id: pos_integer(),
          permissions: [binary()],
          profile: Profile.t(),
          profile_id: pos_integer(),
          current_filters: current_filters(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type current_filters() :: %__MODULE__.CurrentFilters{
          classes_ids: [pos_integer()],
          subjects_ids: [pos_integer()],
          years_ids: [pos_integer()],
          cycles_ids: [pos_integer()],
          assessment_view: String.t(),
          assessment_group_by: String.t(),
          students_ids: [pos_integer()],
          student_record_types_ids: [pos_integer()],
          student_record_statuses_ids: [pos_integer()]
        }

  schema "profile_settings" do
    field :permissions, {:array, :string}, default: []
    belongs_to :profile, Profile

    embeds_one :current_filters, CurrentFilters, on_replace: :delete, primary_key: false do
      field :classes_ids, {:array, :id}
      field :subjects_ids, {:array, :id}
      field :years_ids, {:array, :id}
      field :cycles_ids, {:array, :id}
      field :assessment_view, :string
      field :assessment_group_by, :string
      field :students_ids, {:array, :id}
      field :student_record_types_ids, {:array, :id}
      field :student_record_statuses_ids, {:array, :id}
    end

    timestamps()
  end

  @doc false
  def changeset(profile_settings, attrs) do
    profile_settings
    |> cast(attrs, [:profile_id, :permissions])
    |> validate_required([:profile_id])
    |> cast_embed(:current_filters, with: &current_filters_changeset/2)
    |> validate_change(:permissions, fn :permissions, permissions ->
      valid_permissions = Personalization.list_valid_permissions()

      if Enum.all?(permissions, &(&1 in valid_permissions)),
        do: [],
        else: [permissions: gettext("Invalid permissions")]
    end)
  end

  defp current_filters_changeset(current_filters, attrs) do
    current_filters
    |> cast(attrs, [
      :classes_ids,
      :subjects_ids,
      :years_ids,
      :cycles_ids,
      :assessment_view,
      :assessment_group_by,
      :students_ids,
      :student_record_types_ids,
      :student_record_statuses_ids
    ])
    |> validate_change(:assessment_view, fn :assessment_view, view ->
      if view in ["teacher", "student", "compare"],
        do: [],
        else: [assessment_view: gettext("Invalid assessment view")]
    end)
    |> validate_change(:assessment_group_by, fn :assessment_group_by, view ->
      if view in ["curriculum", "moment"],
        do: [],
        else: [assessment_group_by: gettext("Invalid assessment group by option")]
    end)
  end
end
