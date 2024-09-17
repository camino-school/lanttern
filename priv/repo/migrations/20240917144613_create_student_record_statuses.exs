defmodule Lanttern.Repo.Migrations.CreateStudentRecordStatuses do
  use Ecto.Migration

  def change do
    create table(:student_record_statuses) do
      add :name, :text, null: false
      add :bg_color, :string, null: false
      add :text_color, :string, null: false
      add :school_id, references(:schools, on_delete: :nothing), null: false

      timestamps()
    end

    # already prepare for composite fk in students records
    create unique_index(:student_record_statuses, [:school_id, :id])

    create constraint(
             :student_record_statuses,
             :student_record_status_bg_color_should_be_hex,
             check: "bg_color ~* '^#[a-f0-9]{6}$'"
           )

    create constraint(
             :student_record_statuses,
             :student_record_status_text_color_should_be_hex,
             check: "text_color ~* '^#[a-f0-9]{6}$'"
           )
  end
end
