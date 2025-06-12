defmodule Lanttern.Repo.Migrations.CreateQuizItemStudentEntries do
  use Ecto.Migration

  def change do
    # creating unique constraint to allow composite foreign key on quiz item alternative.
    create unique_index(:quiz_item_alternatives, [:id, :quiz_item_id])

    create table(:quiz_item_student_entries) do
      add :answer, :text
      add :reasoning, :text
      add :score, :float
      add :feedback, :text
      add :quiz_item_id, references(:quiz_items, on_delete: :nothing), null: false
      add :student_id, references(:students, on_delete: :nothing), null: false

      add :quiz_item_alternative_id,
          references(:quiz_item_alternatives,
            with: [quiz_item_id: :quiz_item_id],
            on_delete: :nothing
          )

      timestamps()
    end

    create index(:quiz_item_student_entries, [:quiz_item_id])
    create index(:quiz_item_student_entries, [:quiz_item_alternative_id])
    create unique_index(:quiz_item_student_entries, [:student_id, :quiz_item_id])

    required_input_check = """
    (answer IS NOT NULL AND quiz_item_alternative_id IS NULL)
    OR (answer IS NULL AND quiz_item_alternative_id IS NOT NULL)
    """

    create constraint(
             :quiz_item_student_entries,
             :required_input,
             check: required_input_check
           )
  end
end
