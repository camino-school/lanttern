defmodule Lanttern.Repo.Migrations.CreateStudentTags do
  use Ecto.Migration

  def up do
    # Create schools_student_tags table
    create table(:schools_student_tags) do
      add :name, :text, null: false
      add :bg_color, :string, null: false
      add :text_color, :string, null: false
      add :school_id, references(:schools, on_delete: :nothing), null: false
      add :position, :integer, null: false, default: 0

      timestamps()
    end

    create index(:schools_student_tags, [:position])
    create unique_index(:schools_student_tags, [:school_id, :id])

    create constraint(
             :schools_student_tags,
             :schools_student_tags_bg_color_should_be_hex,
             check: "bg_color ~* '^#[a-f0-9]{6}$'"
           )

    create constraint(
             :schools_student_tags,
             :schools_student_tags_text_color_should_be_hex,
             check: "text_color ~* '^#[a-f0-9]{6}$'"
           )

    # Create relationship table students_tags
    create table(:students_tags, primary_key: false) do
      add :student_id,
          references(:students, with: [school_id: :school_id], on_delete: :delete_all),
          primary_key: true

      add :tag_id,
          references(:schools_student_tags,
            with: [school_id: :school_id],
            on_delete: :nothing
          ),
          primary_key: true

      add :school_id, references(:schools, on_delete: :nothing), null: false
    end
  end

  def down do
    drop table(:students_tags)
    drop table(:schools_student_tags)
  end
end
