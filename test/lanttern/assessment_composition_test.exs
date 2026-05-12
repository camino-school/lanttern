defmodule Lanttern.AssessmentCompositionTest do
  use Lanttern.DataCase

  alias Lanttern.AssessmentComposition
  alias Lanttern.AssessmentComposition.Component
  alias Lanttern.Identity.Scope

  import Lanttern.Factory

  @staff_scope %Scope{profile_type: "staff"}
  @student_scope %Scope{profile_type: "student"}

  describe "list_assessment_point_components/2" do
    test "returns empty list when no components exist for parent" do
      parent_ap = insert(:assessment_point)

      assert AssessmentComposition.list_assessment_point_components(@staff_scope, parent_ap.id) ==
               []
    end

    test "returns only components for the given parent_id" do
      parent_ap = insert(:assessment_point)
      other_parent_ap = insert(:assessment_point)
      child_ap = insert(:assessment_point)
      other_child_ap = insert(:assessment_point)

      insert(:assessment_point_component, parent: parent_ap, component: child_ap)
      insert(:assessment_point_component, parent: other_parent_ap, component: other_child_ap)

      result = AssessmentComposition.list_assessment_point_components(@staff_scope, parent_ap.id)

      assert [component] = result
      assert component.parent_id == parent_ap.id
      assert component.component_id == child_ap.id
    end

    test "preloads scale and curriculum_item with curriculum_component on each component" do
      parent_ap = insert(:assessment_point)
      child_ap = insert(:assessment_point)
      insert(:assessment_point_component, parent: parent_ap, component: child_ap)

      [component] =
        AssessmentComposition.list_assessment_point_components(@staff_scope, parent_ap.id)

      assert %Lanttern.Grading.Scale{} = component.component.scale
      assert %Lanttern.Curricula.CurriculumItem{} = component.component.curriculum_item

      assert %Lanttern.Curricula.CurriculumComponent{} =
               component.component.curriculum_item.curriculum_component
    end

    test "orders moment APs before strand APs (nulls last on moment_id), then by position" do
      parent_ap = insert(:assessment_point)
      moment = insert(:moment)

      moment_ap = insert(:assessment_point, moment_id: moment.id, position: 1)
      strand_ap = insert(:assessment_point, position: 0)

      comp_moment = insert(:assessment_point_component, parent: parent_ap, component: moment_ap)
      comp_strand = insert(:assessment_point_component, parent: parent_ap, component: strand_ap)

      result = AssessmentComposition.list_assessment_point_components(@staff_scope, parent_ap.id)

      assert [first, second] = result
      assert first.id == comp_moment.id
      assert second.id == comp_strand.id
    end
  end

  describe "create_assessment_point_component/2" do
    test "creates component with valid attrs" do
      parent_ap = insert(:assessment_point)
      child_ap = insert(:assessment_point)

      assert {:ok, %Component{} = component} =
               AssessmentComposition.create_assessment_point_component(@staff_scope, %{
                 parent_id: parent_ap.id,
                 component_id: child_ap.id,
                 weight: 1.5
               })

      assert component.parent_id == parent_ap.id
      assert component.component_id == child_ap.id
      assert component.weight == 1.5
    end

    test "returns error changeset when required attrs are missing" do
      parent_ap = insert(:assessment_point)

      assert {:error, %Ecto.Changeset{}} =
               AssessmentComposition.create_assessment_point_component(@staff_scope, %{
                 parent_id: parent_ap.id
               })
    end

    test "returns error changeset when weight is not positive" do
      parent_ap = insert(:assessment_point)
      child_ap = insert(:assessment_point)

      assert {:error, %Ecto.Changeset{} = changeset} =
               AssessmentComposition.create_assessment_point_component(@staff_scope, %{
                 parent_id: parent_ap.id,
                 component_id: child_ap.id,
                 weight: 0.0
               })

      assert %{weight: [_]} = errors_on(changeset)
    end

    test "raises when scope is not staff" do
      parent_ap = insert(:assessment_point)
      child_ap = insert(:assessment_point)

      assert_raise MatchError, fn ->
        AssessmentComposition.create_assessment_point_component(@student_scope, %{
          parent_id: parent_ap.id,
          component_id: child_ap.id,
          weight: 1.0
        })
      end
    end

    test "returns error changeset on duplicate parent_id and component_id pair" do
      parent_ap = insert(:assessment_point)
      child_ap = insert(:assessment_point)

      {:ok, _} =
        AssessmentComposition.create_assessment_point_component(@staff_scope, %{
          parent_id: parent_ap.id,
          component_id: child_ap.id,
          weight: 1.0
        })

      assert {:error, %Ecto.Changeset{}} =
               AssessmentComposition.create_assessment_point_component(@staff_scope, %{
                 parent_id: parent_ap.id,
                 component_id: child_ap.id,
                 weight: 2.0
               })
    end
  end

  describe "update_assessment_point_component/3" do
    test "updates weight with valid attrs" do
      component = insert(:assessment_point_component, weight: 1.0)

      assert {:ok, %Component{} = updated} =
               AssessmentComposition.update_assessment_point_component(@staff_scope, component, %{
                 weight: 2.5
               })

      assert updated.weight == 2.5
    end

    test "returns error changeset when weight is invalid" do
      component = insert(:assessment_point_component, weight: 1.0)

      assert {:error, %Ecto.Changeset{} = changeset} =
               AssessmentComposition.update_assessment_point_component(@staff_scope, component, %{
                 weight: -1.0
               })

      assert %{weight: [_]} = errors_on(changeset)
    end

    test "raises when scope is not staff" do
      component = insert(:assessment_point_component)

      assert_raise MatchError, fn ->
        AssessmentComposition.update_assessment_point_component(@student_scope, component, %{
          weight: 2.0
        })
      end
    end
  end

  describe "delete_assessment_point_component/2" do
    test "deletes the component" do
      component = insert(:assessment_point_component)

      assert {:ok, %Component{}} =
               AssessmentComposition.delete_assessment_point_component(@staff_scope, component)

      assert_raise Ecto.NoResultsError, fn ->
        Lanttern.Repo.get!(Component, component.id)
      end
    end

    test "raises when scope is not staff" do
      component = insert(:assessment_point_component)

      assert_raise MatchError, fn ->
        AssessmentComposition.delete_assessment_point_component(@student_scope, component)
      end
    end
  end

  describe "delete_all_assessment_point_components/2" do
    test "deletes all components for the given parent_id and returns :ok" do
      parent_ap = insert(:assessment_point)
      child_ap_1 = insert(:assessment_point)
      child_ap_2 = insert(:assessment_point)

      insert(:assessment_point_component, parent: parent_ap, component: child_ap_1)
      insert(:assessment_point_component, parent: parent_ap, component: child_ap_2)

      assert :ok =
               AssessmentComposition.delete_all_assessment_point_components(
                 @staff_scope,
                 parent_ap.id
               )

      assert AssessmentComposition.list_assessment_point_components(@staff_scope, parent_ap.id) ==
               []
    end

    test "returns :ok when no components exist for parent" do
      parent_ap = insert(:assessment_point)

      assert :ok =
               AssessmentComposition.delete_all_assessment_point_components(
                 @staff_scope,
                 parent_ap.id
               )
    end

    test "does not delete components belonging to other parents" do
      parent_ap = insert(:assessment_point)
      other_parent_ap = insert(:assessment_point)
      child_ap = insert(:assessment_point)
      other_child_ap = insert(:assessment_point)

      insert(:assessment_point_component, parent: parent_ap, component: child_ap)
      insert(:assessment_point_component, parent: other_parent_ap, component: other_child_ap)

      :ok =
        AssessmentComposition.delete_all_assessment_point_components(@staff_scope, parent_ap.id)

      other_components =
        AssessmentComposition.list_assessment_point_components(@staff_scope, other_parent_ap.id)

      assert [_] = other_components
    end

    test "raises when scope is not staff" do
      parent_ap = insert(:assessment_point)

      assert_raise MatchError, fn ->
        AssessmentComposition.delete_all_assessment_point_components(@student_scope, parent_ap.id)
      end
    end
  end
end
