defmodule Lanttern.Personalization.ProfileReportCardFilter do
  @moduledoc """
  The `ProfileReportCardFilter` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

  alias Lanttern.Identity.Profile
  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Schools.Class

  @type t :: %__MODULE__{
          id: pos_integer(),
          profile: Profile.t(),
          profile_id: pos_integer(),
          report_card: ReportCard.t(),
          report_card_id: pos_integer(),
          class: Class.t(),
          class_id: pos_integer(),
          linked_students_class: Class.t(),
          linked_students_class_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "profile_report_card_filters" do
    belongs_to :profile, Profile
    belongs_to :report_card, ReportCard
    belongs_to :class, Class
    belongs_to :linked_students_class, Class

    timestamps()
  end

  @doc false
  def changeset(profile_report_card_filter, attrs) do
    profile_report_card_filter
    |> cast(attrs, [:profile_id, :report_card_id, :class_id, :linked_students_class_id])
    |> validate_required([:profile_id, :report_card_id])
    |> check_constraint(:class_id,
      name: :required_filter_value,
      message: gettext("Filter value (class or linked students class) is required")
    )
  end
end
