defmodule LantternWeb.AssessmentPointEntryControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.AssessmentsFixtures

  @create_attrs %{observation: "some observation"}
  @update_attrs %{observation: "some updated observation"}
  @invalid_attrs %{student_id: nil}

  describe "index" do
    test "lists all assessment_point_entries", %{conn: conn} do
      conn = get(conn, ~p"/assessments/assessment_point_entries")
      assert html_response(conn, 200) =~ "Listing Assessment point entries"
    end
  end

  describe "new assessment_point_entry" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/assessments/assessment_point_entries/new")
      assert html_response(conn, 200) =~ "New Assessment point entry"
    end
  end

  describe "create assessment_point_entry" do
    test "redirects to show when data is valid", %{conn: conn} do
      assessment_point = assessment_point_fixture()
      student = Lanttern.SchoolsFixtures.student_fixture()

      create_attrs =
        @create_attrs
        |> Map.put_new(:assessment_point_id, assessment_point.id)
        |> Map.put_new(:student_id, student.id)

      conn =
        post(conn, ~p"/assessments/assessment_point_entries",
          assessment_point_entry: create_attrs
        )

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/assessments/assessment_point_entries/#{id}"

      conn = get(conn, ~p"/assessments/assessment_point_entries/#{id}")
      assert html_response(conn, 200) =~ "Assessment point entry #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/assessments/assessment_point_entries",
          assessment_point_entry: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "New Assessment point entry"
    end
  end

  describe "edit assessment_point_entry" do
    setup [:create_assessment_point_entry]

    test "renders form for editing chosen assessment_point_entry", %{
      conn: conn,
      assessment_point_entry: assessment_point_entry
    } do
      conn = get(conn, ~p"/assessments/assessment_point_entries/#{assessment_point_entry}/edit")
      assert html_response(conn, 200) =~ "Edit Assessment point entry"
    end
  end

  describe "update assessment_point_entry" do
    setup [:create_assessment_point_entry]

    test "redirects when data is valid", %{
      conn: conn,
      assessment_point_entry: assessment_point_entry
    } do
      conn =
        put(conn, ~p"/assessments/assessment_point_entries/#{assessment_point_entry}",
          assessment_point_entry: @update_attrs
        )

      assert redirected_to(conn) ==
               ~p"/assessments/assessment_point_entries/#{assessment_point_entry}"

      conn = get(conn, ~p"/assessments/assessment_point_entries/#{assessment_point_entry}")
      assert html_response(conn, 200) =~ "some updated observation"
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      assessment_point_entry: assessment_point_entry
    } do
      conn =
        put(conn, ~p"/assessments/assessment_point_entries/#{assessment_point_entry}",
          assessment_point_entry: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Assessment point entry"
    end
  end

  describe "delete assessment_point_entry" do
    setup [:create_assessment_point_entry]

    test "deletes chosen assessment_point_entry", %{
      conn: conn,
      assessment_point_entry: assessment_point_entry
    } do
      conn = delete(conn, ~p"/assessments/assessment_point_entries/#{assessment_point_entry}")
      assert redirected_to(conn) == ~p"/assessments/assessment_point_entries"

      assert_error_sent 404, fn ->
        get(conn, ~p"/assessments/assessment_point_entries/#{assessment_point_entry}")
      end
    end
  end

  defp create_assessment_point_entry(_) do
    assessment_point_entry = assessment_point_entry_fixture()
    %{assessment_point_entry: assessment_point_entry}
  end
end
