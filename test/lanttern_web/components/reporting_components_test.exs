defmodule LantternWeb.ReportingComponentsTest do
  use Lanttern.DataCase, async: true
  import Phoenix.LiveViewTest

  alias LantternWeb.ReportingComponents

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
