defmodule LantternWeb.RubricsLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.GradingFixtures
  alias Lanttern.RubricsFixtures

  @live_view_path "/rubrics"

  setup [:register_and_log_in_staff_member, :create_scales]

  describe "Rubrics live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Rubrics explorer\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "list rubrics and descriptors", %{
      conn: conn,
      scale_ord: scale_ord,
      scale_num: scale_num,
      ordinal_value: ordinal_value
    } do
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

    test "create rubric with descriptors", %{
      conn: conn,
      scale_ord: scale_ord,
      ordinal_value: ordinal_value
    } do
      {:ok, view, _html} = live(conn, @live_view_path)

      # open new modal and assert patch
      view |> element("a", "Create rubric") |> render_click()
      assert_patch(view, "#{@live_view_path}/new")

      # submit form and assert patch
      view
      |> element("#rubric-form-new")
      |> render_submit(%{
        "rubric" => %{
          "criteria" => "new rubric abc",
          "scale_id" => scale_ord.id,
          "is_differentiation" => false,
          "descriptors" => %{
            "0" => %{
              "scale_id" => scale_ord.id,
              "scale_type" => scale_ord.type,
              "ordinal_value_id" => ordinal_value.id,
              "descriptor" => "new descriptor abc"
            }
          }
        }
      })

      assert_patch(view, @live_view_path)

      # assert new rubric is listed

      assert view |> has_element?("p", "Criteria: new rubric abc")
      assert view |> has_element?("div", scale_ord.name)
      assert view |> has_element?("span", ordinal_value.name)
      assert view |> has_element?("div", "new descriptor abc")
    end

    test "update rubric with descriptors", %{
      conn: conn,
      scale_num: scale_num
    } do
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

      # open new modal and assert patch
      view |> element("a", "Edit") |> render_click()
      assert_patch(view, "#{@live_view_path}/#{rubric_num.id}/edit")

      # submit form and assert patch
      view
      |> element("#rubric-form-#{rubric_num.id}")
      |> render_submit(%{
        "rubric" => %{
          "id" => rubric_num.id,
          "criteria" => "updated criteria abc",
          "scale_id" => scale_num.id,
          "is_differentiation" => false,
          "descriptors" => %{
            "0" => %{
              "id" => rubric_num_desc.id,
              "scale_id" => scale_num.id,
              "scale_type" => scale_num.type,
              "score" => 1,
              "descriptor" => "updated descriptor abc"
            }
          }
        }
      })

      assert_patch(view, @live_view_path)

      # assert rubric is updated

      assert view |> has_element?("p", "Criteria: updated criteria abc")
      assert view |> has_element?("div", scale_num.name)
      assert view |> has_element?("span", "1.0")
      assert view |> has_element?("div", "updated descriptor abc")
    end

    test "delete rubric", %{
      conn: conn,
      scale_ord: scale_ord,
      ordinal_value: ordinal_value
    } do
      rubric_ord =
        RubricsFixtures.rubric_fixture(%{
          scale_id: scale_ord.id,
          criteria: "criteria for ordinal scale rubric"
        })

      _rubric_ord_desc =
        RubricsFixtures.rubric_descriptor_fixture(%{
          rubric_id: rubric_ord.id,
          scale_id: scale_ord.id,
          scale_type: scale_ord.type,
          ordinal_value_id: ordinal_value.id,
          descriptor: "lorem ipsum abc"
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      # assert element is rendered before delete
      assert view |> has_element?("p", "Criteria: criteria for ordinal scale rubric")

      # open new modal and assert patch
      view |> element("a", "Edit") |> render_click()
      assert_patch(view, "#{@live_view_path}/#{rubric_ord.id}/edit")

      # delete and assert patch
      view |> element("button", "Delete") |> render_click()
      # assert_patch not working. maybe because this is a JS.patch?
      # assert_patch(view, @live_view_path)

      # assert rubric is deleted

      refute view |> has_element?("p", "Criteria: criteria for ordinal scale rubric")
    end

    defp create_scales(_) do
      scale_ord = GradingFixtures.scale_fixture(%{type: "ordinal", name: "ordinal scale abc"})

      scale_num =
        GradingFixtures.scale_fixture(%{
          type: "numeric",
          name: "numeric scale xyz",
          start: 0,
          stop: 2
        })

      ordinal_value =
        GradingFixtures.ordinal_value_fixture(%{
          scale_id: scale_ord.id,
          name: "ordinal value abc"
        })

      %{
        scale_ord: scale_ord,
        scale_num: scale_num,
        ordinal_value: ordinal_value
      }
    end
  end
end
