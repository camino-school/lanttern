defmodule LantternWeb.RubricsLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.GradingFixtures
  alias Lanttern.RubricsFixtures

  @live_view_path "/rubrics"

  setup :register_and_log_in_user

  describe "Rubrics live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Rubrics explorer\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "list rubrics and descriptors", %{conn: conn} do
      scale_ord = GradingFixtures.scale_fixture(%{type: "ordinal", name: "ordinal scale abc"})

      scale_num =
        GradingFixtures.scale_fixture(%{
          type: "numeric",
          name: "numeric scale xyz",
          start: 0,
          stop: 2
        })

      ordinal_value =
        GradingFixtures.ordinal_value_fixture(%{scale_id: scale_ord.id, name: "ordinal value abc"})

      rubric_ord =
        RubricsFixtures.rubric_fixture(%{
          scale_id: scale_ord.id,
          criteria: "criteria for ordinal scale rubric"
        })

      rubric_ord_desc =
        RubricsFixtures.rubric_descriptor_fixture(%{
          rubric_id: rubric_ord.id,
          scale_id: scale_ord.id,
          scale_type: scale_ord.type,
          ordinal_value_id: ordinal_value.id,
          descriptor: "lorem ipsum abc"
        })

      rubric_num =
        RubricsFixtures.rubric_fixture(%{
          scale_id: scale_num.id,
          criteria: "criteria for numeric scale rubric"
        })

      rubric_num_desc =
        RubricsFixtures.rubric_descriptor_fixture(%{
          rubric_id: rubric_num.id,
          scale_id: scale_num.id,
          scale_type: scale_num.type,
          score: 1,
          descriptor: "lorem ipsum xyz"
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("p", "Criteria: #{rubric_ord.criteria}")
      assert view |> has_element?("div", scale_ord.name)
      assert view |> has_element?("span", ordinal_value.name)
      assert view |> has_element?("div", rubric_ord_desc.descriptor)

      assert view |> has_element?("p", "Criteria: #{rubric_num.criteria}")
      assert view |> has_element?("div", scale_num.name)
      assert view |> has_element?("span", "#{rubric_num_desc.score}")
      assert view |> has_element?("div", rubric_num_desc.descriptor)
    end
  end
end
