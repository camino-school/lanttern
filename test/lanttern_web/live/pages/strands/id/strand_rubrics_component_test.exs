defmodule LantternWeb.StrandLive.StrandRubricsComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.AssessmentsFixtures
  alias Lanttern.RubricsFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_staff_member]

  describe "rubric form overlay" do
    test "opens edit rubric overlay without scope error", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      strand = insert(:strand)
      scale = insert(:scale)
      curriculum_item = insert(:curriculum_item, school_id: school_id)

      AssessmentsFixtures.assessment_point_fixture(%{
        strand_id: strand.id,
        scale_id: scale.id,
        curriculum_item_id: curriculum_item.id
      })

      rubric =
        RubricsFixtures.rubric_fixture(%{
          strand_id: strand.id,
          scale_id: scale.id,
          curriculum_item_id: curriculum_item.id
        })

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/rubrics?edit_rubric=#{rubric.id}")
      |> assert_has("p", text: "Rubric for curriculum item")
    end
  end
end
