defmodule Lanttern.Personalization.ProfileSettings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "profile_settings" do
    belongs_to :profile, Lanttern.Identity.Profile

    embeds_one :current_filters, CurrentFilters, on_replace: :delete, primary_key: false do
      field :classes_ids, {:array, :id}
      field :subjects_ids, {:array, :id}
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
    |> cast(attrs, [:classes_ids, :subjects_ids])
  end
end
