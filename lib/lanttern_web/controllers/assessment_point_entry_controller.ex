defmodule LantternWeb.AssessmentPointEntryController do
  use LantternWeb, :controller

  import LantternWeb.AssessmentsHelpers
  import LantternWeb.GradingHelpers
  import LantternWeb.SchoolsHelpers
  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPointEntry

  def index(conn, _params) do
    assessment_point_entries = Assessments.list_assessment_point_entries()
    render(conn, :index, assessment_point_entries: assessment_point_entries)
  end

  def new(conn, _params) do
    assessment_point_options = generate_assessment_point_options()
    student_options = generate_student_options()
    ordinal_value_options = generate_ordinal_value_options()
    changeset = Assessments.change_assessment_point_entry(%AssessmentPointEntry{})

    render(conn, :new,
      assessment_point_options: assessment_point_options,
      student_options: student_options,
      ordinal_value_options: ordinal_value_options,
      changeset: changeset
    )
  end

  def create(conn, %{"assessment_point_entry" => assessment_point_entry_params}) do
    case Assessments.create_assessment_point_entry(assessment_point_entry_params) do
      {:ok, assessment_point_entry} ->
        conn
        |> put_flash(:info, "Assessment point entry created successfully.")
        |> redirect(to: ~p"/admin/assessments/assessment_point_entries/#{assessment_point_entry}")

      {:error, %Ecto.Changeset{} = changeset} ->
        assessment_point_options = generate_assessment_point_options()
        student_options = generate_student_options()
        ordinal_value_options = generate_ordinal_value_options()

        render(conn, :new,
          assessment_point_options: assessment_point_options,
          student_options: student_options,
          ordinal_value_options: ordinal_value_options,
          changeset: changeset
        )
    end
  end

  def show(conn, %{"id" => id}) do
    assessment_point_entry = Assessments.get_assessment_point_entry!(id)
    render(conn, :show, assessment_point_entry: assessment_point_entry)
  end

  def edit(conn, %{"id" => id}) do
    assessment_point_entry = Assessments.get_assessment_point_entry!(id)
    assessment_point_options = generate_assessment_point_options()
    student_options = generate_student_options()
    ordinal_value_options = generate_ordinal_value_options()
    changeset = Assessments.change_assessment_point_entry(assessment_point_entry)

    render(conn, :edit,
      assessment_point_entry: assessment_point_entry,
      assessment_point_options: assessment_point_options,
      student_options: student_options,
      ordinal_value_options: ordinal_value_options,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "assessment_point_entry" => assessment_point_entry_params}) do
    assessment_point_entry = Assessments.get_assessment_point_entry!(id)

    case Assessments.update_assessment_point_entry(
           assessment_point_entry,
           assessment_point_entry_params
         ) do
      {:ok, assessment_point_entry} ->
        conn
        |> put_flash(:info, "Assessment point entry updated successfully.")
        |> redirect(to: ~p"/admin/assessments/assessment_point_entries/#{assessment_point_entry}")

      {:error, %Ecto.Changeset{} = changeset} ->
        assessment_point_options = generate_assessment_point_options()
        student_options = generate_student_options()
        ordinal_value_options = generate_ordinal_value_options()

        render(conn, :edit,
          assessment_point_entry: assessment_point_entry,
          assessment_point_options: assessment_point_options,
          student_options: student_options,
          ordinal_value_options: ordinal_value_options,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    assessment_point_entry = Assessments.get_assessment_point_entry!(id)

    {:ok, _assessment_point_entry} =
      Assessments.delete_assessment_point_entry(assessment_point_entry)

    conn
    |> put_flash(:info, "Assessment point entry deleted successfully.")
    |> redirect(to: ~p"/admin/assessments/assessment_point_entries")
  end
end
