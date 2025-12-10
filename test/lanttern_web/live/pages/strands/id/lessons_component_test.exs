defmodule LantternWeb.StrandLive.LessonsComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  @live_view_base_path "/strands"

  setup [:register_and_log_in_staff_member]

  describe "Moment management" do
    test "create moment", %{conn: conn} do
      subject = insert(:subject, name: "Subject abc")
      strand = insert(:strand, subjects: [subject])

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> click_button("Create new moment")
      |> within("#moment-form-overlay", fn conn ->
        conn
        |> fill_in("Name", with: "Moment name abc")
        |> fill_in("Description", with: "Moment description abc")
        |> select("Subjects", option: "Subject abc")
        |> click_button("Save")
      end)
      |> assert_has("a", text: "Moment name abc")
    end

    test "edit moment", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> click_button("#moments-#{moment.id} button", "Edit")
      |> within("#moment-form-overlay", fn conn ->
        conn
        |> fill_in("Name", with: "Moment zzz")
        |> click_button("Save")
      end)
      |> assert_has("a", text: "Moment zzz")
    end

    test "delete moment", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> click_button("#moments-#{moment.id} button", "Edit")
      |> click_button("#moment-form-overlay button", "Delete")
      |> refute_has("#moments-#{moment.id}")
    end
  end

  describe "Lessons filtering" do
    test "list all lessons", %{conn: conn} do
      subject_a = insert(:subject, name: "Subject A")
      subject_b = insert(:subject, name: "Subject B")
      strand = insert(:strand, subjects: [subject_a, subject_b])
      moment = insert(:moment, strand: strand)

      insert(:lesson, strand: strand, moment: moment, subjects: [subject_a], name: "Lesson A")
      insert(:lesson, strand: strand, moment: moment, subjects: [subject_b], name: "Lesson B")

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> assert_has("h4", text: "Lesson A")
      |> assert_has("h4", text: "Lesson B")
    end

    test "list lessons filtered by subject", %{conn: conn} do
      subject_a = insert(:subject, name: "Subject A")
      subject_b = insert(:subject, name: "Subject B")
      strand = insert(:strand, subjects: [subject_a, subject_b])
      moment = insert(:moment, strand: strand)

      insert(:lesson, strand: strand, moment: moment, subjects: [subject_a], name: "Lesson A")
      insert(:lesson, strand: strand, moment: moment, subjects: [subject_b], name: "Lesson B")

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> click_link("#lesson-filter-options a", "Subject A")
      |> assert_has("h4", text: "Lesson A")
      |> refute_has("h4", text: "Lesson B")
    end
  end
end
