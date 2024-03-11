defmodule Lanttern.Repo.Migrations.CreateGradeComponents do
  use Ecto.Migration

  def change do
    create table(:grade_components) do
      add :weight, :float, null: false, default: 1.0
      add :position, :integer, null: false, default: 0
      add :report_card_id, references(:report_cards, on_delete: :nothing), null: false
      add :assessment_point_id, references(:assessment_points, on_delete: :nothing), null: false
      add :subject_id, references(:subjects, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:grade_components, [:report_card_id])
    create index(:grade_components, [:assessment_point_id])
    create unique_index(:grade_components, [:subject_id, :assessment_point_id, :report_card_id])

    create constraint(:grade_components, :weight_must_be_non_negative, check: "weight >= 0.0")
  end
end
