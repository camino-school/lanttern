defmodule LantternWeb.MomentLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.LearningContextFixtures

  @live_view_base_path "/strands/moment"

  setup [:register_and_log_in_staff_member]

  describe "Moment details live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture(%{name: "strand abc"})

      moment =
        LearningContextFixtures.moment_fixture(%{name: "moment abc", strand_id: strand.id})

      conn = get(conn, "#{@live_view_base_path}/#{moment.id}")

      # assert html_response(conn, 200) =~ ~r"<h3>.+strand abc.+</h3>"
      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*moment abc\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "display moment basic info", %{conn: conn} do
      moment =
        LearningContextFixtures.moment_fixture(%{
          name: "moment abc",
          description: "moment description abc"
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}")

      assert view |> has_element?("h1", moment.name)
      assert view |> has_element?("p", "moment description abc")
    end
  end

  describe "Moment management" do
    test "edit moment", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand, name: "moment abc")

      conn
      |> visit("#{@live_view_base_path}/#{moment.id}")
      |> click_button("Edit")
      |> within("#moment-form-overlay", fn conn ->
        conn
        |> fill_in("Name", with: "moment name xyz")
        |> click_button("Save")
      end)
      |> assert_has("h1", text: "moment name xyz")
    end

    test "delete moment", %{conn: conn} do
      strand = insert(:strand, name: "strand abc")
      moment = insert(:moment, strand: strand)

      conn
      |> visit("#{@live_view_base_path}/#{moment.id}")
      |> click_button("Edit")
      |> within("#moment-form-overlay", fn conn ->
        conn
        |> click_button("Delete")
      end)
      |> assert_has("h1", text: "strand abc")
    end

    test "delete moment with linked lessons shows confirmation options", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      insert(:lesson, strand: strand, moment: moment)

      conn
      |> visit("#{@live_view_base_path}/#{moment.id}")
      |> click_button("Edit")
      |> within("#moment-form-overlay", fn conn ->
        conn
        |> click_button("Delete")
        |> assert_has("p", text: "This moment has linked lessons. What would you like to do?")
        |> assert_has("button", text: "Keep lessons (detach from moment)")
        |> assert_has("button", text: "Delete lessons too")
      end)
    end

    test "delete moment and detach lessons keeps lessons in db", %{conn: conn} do
      strand = insert(:strand, name: "strand abc")
      moment = insert(:moment, strand: strand)
      lesson = insert(:lesson, strand: strand, moment: moment)

      conn
      |> visit("#{@live_view_base_path}/#{moment.id}")
      |> click_button("Edit")
      |> within("#moment-form-overlay", fn conn ->
        conn
        |> click_button("Delete")
        |> click_button("Keep lessons (detach from moment)")
      end)
      |> assert_has("h1", text: "strand abc")

      assert Lanttern.Repo.get!(Lanttern.Lessons.Lesson, lesson.id).moment_id == nil
    end

    test "delete moment and its lessons removes lessons from db", %{conn: conn} do
      strand = insert(:strand, name: "strand abc")
      moment = insert(:moment, strand: strand)
      lesson = insert(:lesson, strand: strand, moment: moment)

      conn
      |> visit("#{@live_view_base_path}/#{moment.id}")
      |> click_button("Edit")
      |> within("#moment-form-overlay", fn conn ->
        conn
        |> click_button("Delete")
        |> click_button("Delete lessons too")
      end)
      |> assert_has("h1", text: "strand abc")

      assert Lanttern.Repo.get(Lanttern.Lessons.Lesson, lesson.id) == nil
    end
  end

  describe "Moment description" do
    test "add description when moment has none", %{conn: conn} do
      moment = insert(:moment)

      conn
      |> visit("#{@live_view_base_path}/#{moment.id}")
      |> click_button("Add description")
      |> fill_in("Moment description", with: "New description abc")
      |> click_button("#moment-description-form button", "Save")
      |> assert_has("p", text: "New description abc")
    end

    test "edit existing description", %{conn: conn} do
      moment = insert(:moment, description: "Old description abc")

      conn
      |> visit("#{@live_view_base_path}/#{moment.id}")
      |> click_button("Edit description")
      |> fill_in("Moment description", with: "Updated description xyz")
      |> click_button("#moment-description-form button", "Save")
      |> assert_has("p", text: "Updated description xyz")
    end
  end
end
