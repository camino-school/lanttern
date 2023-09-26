defmodule LantternWeb.AssessmentPointController do
  use LantternWeb, :controller

  import LantternWeb.CurriculaHelpers
  import LantternWeb.GradingHelpers
  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint

  def index(conn, _params) do
    assessment_points = Assessments.list_assessment_points()
    render(conn, :index, assessment_points: assessment_points)
  end

  def new(conn, _params) do
    curriculum_item_options = generate_curriculum_item_options()
    scale_options = generate_scale_options()
    changeset = Assessments.change_assessment_point(%AssessmentPoint{})

    render(conn, :new,
      curriculum_item_options: curriculum_item_options,
      scale_options: scale_options,
      changeset: changeset
    )
  end

  def create(conn, %{"assessment_point" => assessment_point_params}) do
    case Assessments.create_assessment_point(assessment_point_params) do
      {:ok, assessment} ->
        conn
        |> put_flash(:info, "Assessment created successfully.")
        |> redirect(to: ~p"/admin/assessment_points/#{assessment}")

      {:error, %Ecto.Changeset{} = changeset} ->
        curriculum_item_options = generate_curriculum_item_options()
        scale_options = generate_scale_options()

        render(conn, :new,
          curriculum_item_options: curriculum_item_options,
          scale_options: scale_options,
          changeset: changeset
        )
    end
  end

  def show(conn, %{"id" => id}) do
    assessment_point = Assessments.get_assessment_point!(id)
    render(conn, :show, assessment_point: assessment_point)
  end

  def edit(conn, %{"id" => id}) do
    assessment_point = Assessments.get_assessment_point!(id)
    curriculum_item_options = generate_curriculum_item_options()
    scale_options = generate_scale_options()
    changeset = Assessments.change_assessment_point(assessment_point)

    render(conn, :edit,
      assessment_point: assessment_point,
      curriculum_item_options: curriculum_item_options,
      scale_options: scale_options,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "assessment_point" => assessment_point_params}) do
    assessment_point = Assessments.get_assessment_point!(id)

    case Assessments.update_assessment_point(assessment_point, assessment_point_params) do
      {:ok, assessment_point} ->
        conn
        |> put_flash(:info, "Assessment updated successfully.")
        |> redirect(to: ~p"/admin/assessment_points/#{assessment_point}")

      {:error, %Ecto.Changeset{} = changeset} ->
        curriculum_item_options = generate_curriculum_item_options()
        scale_options = generate_scale_options()

        render(conn, :edit,
          assessment_point: assessment_point,
          curriculum_item_options: curriculum_item_options,
          scale_options: scale_options,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    assessment_point = Assessments.get_assessment_point!(id)
    {:ok, _assessment_point} = Assessments.delete_assessment_point(assessment_point)

    conn
    |> put_flash(:info, "Assessment point deleted successfully.")
    |> redirect(to: ~p"/admin/assessment_points")
  end
end
