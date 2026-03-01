defmodule Lanttern.Engagement.DailyActiveProfile do
  @moduledoc """
  Schema for tracking daily active profiles.

  Records one row per profile per day. Used to compute DAU metrics.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @schema_prefix "analytics"

  schema "daily_active_profiles" do
    field :profile_id, :integer
    field :date, :date

    timestamps(updated_at: false)
  end

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          profile_id: pos_integer(),
          date: Date.t(),
          inserted_at: NaiveDateTime.t() | nil
        }

  def changeset(daily_active_profile, attrs) do
    daily_active_profile
    |> cast(attrs, [:profile_id, :date])
    |> validate_required([:profile_id, :date])
  end
end
