defmodule LantternWeb.BnccEfLiveTest do
  use LantternWeb.ConnCase

  @live_view_path "/curriculum/bncc_ef"

  setup :register_and_log_in_teacher

  describe "Curriculum BNCC live view" do
    import Lanttern.BNCCFixtures
    import Lanttern.TaxonomyFixtures

    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*BNCC Ensino Fundamental\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "list and filter results", %{conn: conn} do
      sub_lp = subject_fixture(%{code: "port"})
      sub_ma = subject_fixture(%{code: "math"})
      year_ef1 = year_fixture(%{code: "g1"})
      year_ef2 = year_fixture(%{code: "g2"})

      {_ca, _pl, _oc, ha_lp} =
        habilidade_bncc_ef_lp_fixture(%{
          code: "EF01LP01",
          subjects_ids: [sub_lp.id],
          years_ids: [year_ef1.id]
        })

      {_ut, _oc, ha_ma} =
        habilidade_bncc_ef_fixture(%{
          code: "EF02MA01",
          subjects_ids: [sub_ma.id],
          years_ids: [year_ef2.id]
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("td", ha_lp.name)
      assert view |> has_element?("td", ha_ma.name)

      # open modal and assert open
      view
      |> element("button", "Filter")
      |> render_click()

      assert view |> has_element?("h2", "Filter Curriculum")
      assert view |> has_element?("label", sub_lp.name)
      assert view |> has_element?("label", sub_ma.name)

      # submit filter
      view
      |> element("#bncc-ef-filters-form")
      |> render_submit(%{
        "subjects_ids" => ["#{sub_lp.id}"]
      })

      # --- skipping this test for now: https://elixirforum.com/t/testing-a-stream-reset/56094
      # # check filtered results
      # assert render(view) =~ ha_lp.code
      # refute render(view) =~ ha_ma.code
    end
  end
end
