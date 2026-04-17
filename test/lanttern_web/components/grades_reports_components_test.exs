defmodule LantternWeb.GradesReportsComponentsTest do
  use Lanttern.DataCase, async: true
  import Phoenix.LiveViewTest

  alias LantternWeb.GradesReportsComponents
  alias Lanttern.GradesReports.StudentGradesReportEntry

  describe "grade_composition_table/1" do
    test "rounds composition_normalized_value down to 2 decimal places without floating-point error" do
      # 0.99 in IEEE 754 is ~0.98999..., so Float.floor(0.99, 2) = 0.98 (bug)
      entry = %StudentGradesReportEntry{
        composition: [],
        composition_ordinal_value: nil,
        composition_score: 10.0,
        composition_normalized_value: 0.99
      }

      html =
        render_component(
          &GradesReportsComponents.grade_composition_table/1,
          student_grades_report_entry: entry
        )

      assert html =~ "0.99"
    end
  end
end
