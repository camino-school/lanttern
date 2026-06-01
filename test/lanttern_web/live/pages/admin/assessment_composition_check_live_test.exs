defmodule LantternWeb.Admin.AssessmentCompositionCheckLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.Factory

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Repo

  setup :register_and_log_in_root_admin

  defp stale_numeric_composition do
    strand = insert(:strand, name: "Composition check strand")
    numeric_scale = insert(:scale, type: "numeric", max_score: 100.0)
    student = insert(:student, name: "Ada Lovelace")

    parent =
      insert(:assessment_point,
        strand_id: strand.id,
        scale: numeric_scale,
        uses_composition: true,
        name: "Composed point"
      )

    child = insert(:assessment_point, strand_id: strand.id, scale: numeric_scale)
    insert(:assessment_point_component, parent: parent, component: child, weight: 1.0)

    insert(:assessment_point_entry,
      assessment_point: child,
      student: student,
      scale: numeric_scale,
      scale_type: "numeric",
      score: 38.0
    )

    parent_entry =
      insert(:assessment_point_entry,
        assessment_point: parent,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 99.0,
        use_manual_input: false
      )

    %{strand: strand, parent: parent, parent_entry: parent_entry, student: student}
  end

  describe "Assessment composition check page" do
    test "lists an out-of-sync entry on strand select and re-syncs it", %{conn: conn} do
      %{strand: strand, parent: parent, parent_entry: parent_entry, student: student} =
        stale_numeric_composition()

      {:ok, view, _html} = live(conn, ~p"/admin/assessment_composition_check")

      # search + pick the strand through the combobox
      view
      |> form("#strand-search-form", %{"query" => strand.name})
      |> render_change()

      # selection is driven client-side by the Autocomplete hook; simulate the
      # event it pushes to the component
      view
      |> element("#strand-search")
      |> render_hook("autocomplete_result_select", %{"id" => strand.id})

      # the selection is delivered to the LV via an async message — flush it
      html = render(view)

      assert html =~ student.name
      # stored (99) and expected (38) both surface in the out-of-sync row
      assert html =~ "99"
      assert html =~ "38"

      # sync corrects the stored value
      html = view |> element("button", "Sync") |> render_click()
      assert html =~ "All composed entries are in sync"

      assert %AssessmentPointEntry{score: 38.0} =
               Repo.get!(AssessmentPointEntry, parent_entry.id)

      _ = parent
    end
  end
end
