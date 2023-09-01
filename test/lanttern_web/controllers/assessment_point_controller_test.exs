defmodule LantternWeb.AssessmentPointControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.AssessmentsFixtures

  @create_attrs %{
    name: "some name",
    date: ~U[2023-08-02 15:30:00Z],
    description: "some description"
  }
  @update_attrs %{
    name: "some updated name",
    date: ~U[2023-08-03 15:30:00Z],
    description: "some updated description"
  }
  @invalid_attrs %{name: nil, date: nil, description: nil}

  setup %{conn: conn} do
    # log_in user for all test cases
    conn =
      conn
      |> log_in_user(Lanttern.IdentityFixtures.root_admin_fixture())

    [conn: conn]
  end

  describe "index" do
    test "lists all assessment points", %{conn: conn} do
      conn = get(conn, ~p"/admin/assessments/assessment_points")
      assert html_response(conn, 200) =~ "Listing Assessment points"
    end
  end

  describe "new assessment point" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/assessments/assessment_points/new")
      assert html_response(conn, 200) =~ "New Assessment"
    end
  end

  describe "create assessment point" do
    test "redirects to show when data is valid", %{conn: conn} do
      curriculum_item = Lanttern.CurriculaFixtures.curriculum_item_fixture()
      scale = Lanttern.GradingFixtures.scale_fixture()

      create_attrs =
        @create_attrs
        |> Map.put_new(:curriculum_item_id, curriculum_item.id)
        |> Map.put_new(:scale_id, scale.id)

      conn = post(conn, ~p"/admin/assessments/assessment_points", assessment_point: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/assessments/assessment_points/#{id}"

      conn = get(conn, ~p"/admin/assessments/assessment_points/#{id}")
      assert html_response(conn, 200) =~ "Assessment point #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/admin/assessments/assessment_points", assessment_point: @invalid_attrs)

      assert html_response(conn, 200) =~ "New Assessment"
    end
  end

  describe "edit assessment point" do
    setup [:create_assessment]

    test "renders form for editing chosen assessment", %{
      conn: conn,
      assessment_point: assessment_point
    } do
      conn = get(conn, ~p"/admin/assessments/assessment_points/#{assessment_point}/edit")
      assert html_response(conn, 200) =~ "Edit Assessment"
    end
  end

  describe "update assessment point" do
    setup [:create_assessment]

    test "redirects when data is valid", %{conn: conn, assessment_point: assessment_point} do
      conn =
        put(conn, ~p"/admin/assessments/assessment_points/#{assessment_point}",
          assessment_point: @update_attrs
        )

      assert redirected_to(conn) == ~p"/admin/assessments/assessment_points/#{assessment_point}"

      conn = get(conn, ~p"/admin/assessments/assessment_points/#{assessment_point}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, assessment_point: assessment_point} do
      conn =
        put(conn, ~p"/admin/assessments/assessment_points/#{assessment_point}",
          assessment_point: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Assessment"
    end
  end

  describe "delete assessment point" do
    setup [:create_assessment]

    test "deletes chosen assessment point", %{conn: conn, assessment_point: assessment_point} do
      conn = delete(conn, ~p"/admin/assessments/assessment_points/#{assessment_point}")
      assert redirected_to(conn) == ~p"/admin/assessments/assessment_points"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/assessments/assessment_points/#{assessment_point}")
      end
    end
  end

  defp create_assessment(_) do
    assessment_point = assessment_point_fixture()
    %{assessment_point: assessment_point}
  end
end
