defmodule LantternWeb.ReportingComponentsTest do
  use Lanttern.DataCase, async: true
  import Phoenix.LiveViewTest

  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Grading.Scale
  alias LantternWeb.ReportingComponents

  describe "report_scale_ordinal_bar/1" do
    setup do
      scale = %Scale{
        type: "ordinal",
        breakpoints: [0.4, 0.8],
        ordinal_values: [
          %OrdinalValue{
            id: 1,
            name: "C",
            normalized_value: 0.0,
            bg_color: "#ff0000",
            text_color: "#ffffff"
          },
          %OrdinalValue{
            id: 2,
            name: "B",
            normalized_value: 0.5,
            bg_color: "#ffff00",
            text_color: "#000000"
          },
          %OrdinalValue{
            id: 3,
            name: "A",
            normalized_value: 1.0,
            bg_color: "#00ff00",
            text_color: "#000000"
          }
        ]
      }

      %{scale: scale}
    end

    test "renders one colored segment per ordinal value with widths from breakpoints", %{
      scale: scale
    } do
      html =
        render_component(&ReportingComponents.report_scale_ordinal_bar/1, id: "bar", scale: scale)

      # widths: C = 40%, B = 40%, A = 20%
      assert html =~ "width: 40.0%"
      assert html =~ "width: 20.0%"
      # segment colors come from each ordinal value's bg/text color
      assert html =~ "background-color: #ff0000"
      assert html =~ "background-color: #ffff00"
      assert html =~ "background-color: #00ff00"
    end

    test "renders a tooltip per segment with name and range text", %{scale: scale} do
      html =
        render_component(&ReportingComponents.report_scale_ordinal_bar/1, id: "bar", scale: scale)

      assert html =~ "C"
      assert html =~ "B"
      assert html =~ "A"
      # first segment: only an upper bound
      assert html =~ "Less than 0.4"
      # middle segment: both bounds
      assert html =~ "Greater than or equal to 0.4, less than 0.8"
      # last segment: only a lower bound
      assert html =~ "Greater than or equal to 0.8"
    end

    test "positions a marker below the bar showing the rounded normalized value", %{scale: scale} do
      html =
        render_component(&ReportingComponents.report_scale_ordinal_bar/1,
          id: "bar",
          scale: scale,
          entry: %{normalized_value: 0.5625}
        )

      # marker is positioned at the exact normalized value
      assert html =~ "left: 56.25%"
      # value is rounded to 2 decimals (same helper as the composition table)
      assert html =~ "0.56"
      refute html =~ "0.5625"
    end

    test "omits the marker when there is no entry", %{scale: scale} do
      html =
        render_component(&ReportingComponents.report_scale_ordinal_bar/1, id: "bar", scale: scale)

      refute html =~ "left:"
    end

    test "omits the marker when the entry is masked (false)", %{scale: scale} do
      html =
        render_component(&ReportingComponents.report_scale_ordinal_bar/1,
          id: "bar",
          scale: scale,
          entry: false
        )

      refute html =~ "left:"
    end

    test "renders a table view listing each ordinal value with its range", %{scale: scale} do
      html =
        render_component(&ReportingComponents.report_scale_ordinal_bar/1, id: "bar", scale: scale)

      assert html =~ "Greater than or equal to"
      assert html =~ "Less than"
      # open-ended bounds render as an em dash; inner breakpoints render as numbers
      assert html =~ "0.4"
      assert html =~ "0.8"
      assert html =~ "—"
    end

    test "highlights the table row containing the entry's normalized value", %{scale: scale} do
      html =
        render_component(&ReportingComponents.report_scale_ordinal_bar/1,
          id: "bar",
          scale: scale,
          # 0.5 falls in the middle segment B ([0.4, 0.8))
          entry: %{normalized_value: 0.5}
        )

      [active_row] = Regex.run(~r{<tr class="bg-ltrn-lightest">.*?</tr>}s, html)
      assert active_row =~ "B"
      refute active_row =~ ">A<"
    end

    test "does not highlight any table row without an entry", %{scale: scale} do
      html =
        render_component(&ReportingComponents.report_scale_ordinal_bar/1, id: "bar", scale: scale)

      refute html =~ ~s(<tr class="bg-ltrn-lightest">)
    end
  end

  describe "composition_breakdown_table/1" do
    test "renders the average-based table with normalized values at 2 decimal places" do
      ordinal_value = %{
        bg_color: "#ffd230",
        text_color: "#292524",
        short_name: "Pro",
        name: "Progressing"
      }

      breakdown = %{
        scale_type: "ordinal",
        total_weight: 4.0,
        components: [
          %{
            assessment_point: %{moment_id: 1, name: "Component A", is_hidden: false},
            weight: 1.0,
            ordinal_value: ordinal_value,
            score: nil,
            normalized_value: 0.5,
            is_missing: false,
            has_marking: true
          },
          %{
            assessment_point: %{moment_id: 1, name: "Component B", is_hidden: false},
            weight: 1.0,
            ordinal_value: nil,
            score: nil,
            normalized_value: nil,
            is_missing: false,
            has_marking: false
          }
        ],
        composed: %{
          ordinal_value: ordinal_value,
          score: nil,
          normalized_value: 0.5625,
          max_score: nil
        }
      }

      html =
        render_component(&ReportingComponents.composition_breakdown_table/1,
          breakdown: breakdown,
          composed_name: "Composed assessment point"
        )

      # 2 decimal places, always (0.5 -> "0.50", 0.5625 -> "0.56")
      assert html =~ "0.50"
      assert html =~ "0.56"
      # short ordinal value label
      assert html =~ "Pro"
      # component without an entry is surfaced as "No marking" with a "-" normalized
      assert html =~ "No marking"
      assert html =~ "Composed assessment point"
    end

    test "renders the sum-based table with scores and max scores" do
      breakdown = %{
        scale_type: "numeric",
        total_weight: 0.0,
        components: [
          %{
            assessment_point: %{
              moment_id: 1,
              name: "Component A",
              is_hidden: false,
              scale: %{max_score: 20.0}
            },
            weight: 1.0,
            ordinal_value: nil,
            score: 15.0,
            normalized_value: 0.75,
            is_missing: false,
            has_marking: true
          },
          %{
            assessment_point: %{
              moment_id: 1,
              name: "Component B",
              is_hidden: false,
              scale: %{max_score: 40.0}
            },
            weight: 1.0,
            ordinal_value: nil,
            score: nil,
            normalized_value: nil,
            is_missing: false,
            has_marking: false
          }
        ],
        composed: %{ordinal_value: nil, score: 38.0, normalized_value: nil, max_score: 100.0}
      }

      html =
        render_component(&ReportingComponents.composition_breakdown_table/1,
          breakdown: breakdown,
          composed_name: "Composed assessment point"
        )

      assert html =~ "15"
      assert html =~ "20"
      assert html =~ "No marking"
      assert html =~ "38"
      assert html =~ "100"
    end

    test "masks hidden components' values when mask_hidden_components is set" do
      visible_ov = %{bg_color: "#fff", text_color: "#000", short_name: "Pro", name: "Progressing"}
      hidden_ov = %{bg_color: "#fff", text_color: "#000", short_name: "Exc", name: "Exceeding"}

      breakdown = %{
        scale_type: "ordinal",
        total_weight: 2.0,
        components: [
          %{
            assessment_point: %{moment_id: 1, name: "Visible Component", is_hidden: false},
            weight: 1.0,
            ordinal_value: visible_ov,
            score: nil,
            normalized_value: 0.5,
            is_missing: false,
            has_marking: true
          },
          %{
            assessment_point: %{moment_id: 1, name: "Hidden Component", is_hidden: true},
            weight: 1.0,
            ordinal_value: hidden_ov,
            score: nil,
            normalized_value: 0.9,
            is_missing: false,
            has_marking: true
          }
        ],
        composed: %{ordinal_value: nil, score: nil, normalized_value: nil, max_score: nil}
      }

      html =
        render_component(&ReportingComponents.composition_breakdown_table/1,
          breakdown: breakdown,
          composed_name: "Composed assessment point",
          mask_hidden_components: true
        )

      # the hidden component row still renders, but its value is masked
      assert html =~ "Hidden Component"
      assert html =~ "Not available"
      refute html =~ "Exc"
      # the visible component's value is still shown
      assert html =~ "Pro"
    end
  end
end
