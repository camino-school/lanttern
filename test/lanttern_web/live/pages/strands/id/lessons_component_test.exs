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
      |> within("#moments-#{moment.id}", fn conn ->
        conn
        |> click_button("Edit")
      end)
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
      |> within("#moments-#{moment.id}", fn conn ->
        conn
        |> click_button("Edit")
      end)
      |> within("#moment-form-overlay", fn conn ->
        conn
        |> click_button("Delete")
      end)
      |> refute_has("#moments-#{moment.id}")
    end
  end
end
