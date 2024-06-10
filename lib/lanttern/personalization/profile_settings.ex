defmodule Lanttern.Personalization.ProfileSettings do
  @moduledoc """
  The `ProfileSettings` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

  alias Lanttern.Identity.Profile

  @type t :: %__MODULE__{
          id: pos_integer(),
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
          assessment_view: String.t()
        }

  schema "profile_settings" do
    belongs_to :profile, Profile

    embeds_one :current_filters, CurrentFilters, on_replace: :delete, primary_key: false do
      field :classes_ids, {:array, :id}
      field :subjects_ids, {:array, :id}
      field :years_ids, {:array, :id}
      field :cycles_ids, {:array, :id}
      field :assessment_view, :string
    end

    timestamps()
  end

  @doc false
  def changeset(profile_settings, attrs) do
    profile_settings
    |> cast(attrs, [:profile_id])
    |> validate_required([:profile_id])
    |> cast_embed(:current_filters, with: &current_filters_changeset/2)
  end

  defp current_filters_changeset(current_filters, attrs) do
    current_filters
    |> cast(attrs, [:classes_ids, :subjects_ids, :years_ids, :cycles_ids, :assessment_view])
    |> validate_change(:assessment_view, fn :assessment_view, view ->
      if view in ["teacher", "student", "compare"],
        do: [],
        else: [assessment_view: gettext("Invalid assessment view")]
    end)
  end
end
