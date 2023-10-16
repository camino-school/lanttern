defmodule Lanttern.Explorer.AssessmentPointsFilterView do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Lanttern.Repo

  schema "assessment_points_filter_views" do
    field :name, :string
    field :classes_ids, {:array, :id}, virtual: true
    field :subjects_ids, {:array, :id}, virtual: true

    belongs_to :profile, Lanttern.Identity.Profile

    many_to_many :subjects, Lanttern.Taxonomy.Subject,
      join_through: "assessment_points_filter_views_subjects",
      on_replace: :delete,
      preload_order: [asc: :name]

    many_to_many :classes, Lanttern.Schools.Class,
      join_through: "assessment_points_filter_views_classes",
      on_replace: :delete,
      preload_order: [asc: :name]

    timestamps()
  end

  @doc false
  def changeset(assessment_points_filter_view, attrs) do
    assessment_points_filter_view
    |> cast(attrs, [:name, :profile_id, :classes_ids, :subjects_ids])
    |> validate_required([:name, :profile_id])
    |> put_classes()
    |> put_subjects()
  end

  defp put_classes(changeset) do
    put_classes(
      changeset,
      get_change(changeset, :classes_ids)
    )
  end

  defp put_classes(changeset, nil), do: changeset

  defp put_classes(changeset, classes_ids) do
    classes =
      from(c in Lanttern.Schools.Class, where: c.id in ^classes_ids)
      |> Repo.all()

    changeset
    |> put_assoc(:classes, classes)
  end

  defp put_subjects(changeset) do
    put_subjects(
      changeset,
      get_change(changeset, :subjects_ids)
    )
  end

  defp put_subjects(changeset, nil), do: changeset

  defp put_subjects(changeset, subjects_ids) do
    subjects =
      from(s in Lanttern.Taxonomy.Subject, where: s.id in ^subjects_ids)
      |> Repo.all()

    changeset
    |> put_assoc(:subjects, subjects)
  end
end
