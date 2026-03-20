defmodule LantternWeb.GradingHelpersTest do
  use Lanttern.DataCase
  import Lanttern.Factory

  alias Lanttern.IdentityFixtures
  alias LantternWeb.GradingHelpers

  setup do
    scope = IdentityFixtures.scope_fixture(permissions: ["assessment_management"])
    %{scope: scope}
  end

  describe "generate_scale_options/2" do
    test "returns scale options for current school only", %{scope: scope} do
      scale = insert(:scale, school_id: scope.school_id, name: "School Scale")
      _other_school_scale = insert(:scale, name: "Other School Scale")

      options = GradingHelpers.generate_scale_options(scope)

      assert [{school_scale_name, _id}] = options
      assert school_scale_name == scale.name
    end

    test "with only_active: true filters out deactivated scales", %{scope: scope} do
      _active = insert(:scale, school_id: scope.school_id, name: "Active")

      _deactivated =
        insert(:scale, school_id: scope.school_id, deactivated_at: DateTime.utc_now())

      options = GradingHelpers.generate_scale_options(scope, only_active: true)

      assert [{"Active", _id}] = options
    end

    test "with current_scale_id for an deactivated scale injects it with label", %{scope: scope} do
      deactivated =
        insert(:scale,
          school_id: scope.school_id,
          name: "Old Scale",
          deactivated_at: DateTime.utc_now()
        )

      options =
        GradingHelpers.generate_scale_options(scope,
          only_active: true,
          current_scale_id: deactivated.id
        )

      assert [{"Old Scale (current, deactivated)", id} | _rest] = options
      assert id == deactivated.id
    end

    test "with current_scale_id for an active scale does not duplicate it", %{scope: scope} do
      active = insert(:scale, school_id: scope.school_id, name: "Active Scale")

      options =
        GradingHelpers.generate_scale_options(scope,
          only_active: true,
          current_scale_id: active.id
        )

      assert Enum.count(options) == 1
      assert [{"Active Scale", _id}] = options
    end
  end
end
