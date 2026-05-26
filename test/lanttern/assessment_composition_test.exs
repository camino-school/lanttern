defmodule Lanttern.AssessmentCompositionTest do
  use Lanttern.DataCase

  alias Lanttern.AssessmentComposition
  alias Lanttern.AssessmentComposition.Component
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.AssessmentsLog.AssessmentPointEntryLog
  alias Lanttern.Identity.Scope
  alias Lanttern.Repo

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

  describe "replace_assessment_point_components/3" do
    test "inserts new components when none exist" do
      parent_ap = insert(:assessment_point)
      child_ap = insert(:assessment_point)

      assert {:ok, :replaced} =
               AssessmentComposition.replace_assessment_point_components(
                 @staff_scope,
                 parent_ap.id,
                 [
                   %{component_id: child_ap.id, weight: 1.5}
                 ]
               )

      [component] =
        AssessmentComposition.list_assessment_point_components(@staff_scope, parent_ap.id)

      assert component.component_id == child_ap.id
      assert component.weight == 1.5
    end

    test "replaces existing components atomically" do
      parent_ap = insert(:assessment_point)
      old_child = insert(:assessment_point)
      new_child = insert(:assessment_point)

      insert(:assessment_point_component, parent: parent_ap, component: old_child)

      assert {:ok, :replaced} =
               AssessmentComposition.replace_assessment_point_components(
                 @staff_scope,
                 parent_ap.id,
                 [
                   %{component_id: new_child.id, weight: 2.0}
                 ]
               )

      [component] =
        AssessmentComposition.list_assessment_point_components(@staff_scope, parent_ap.id)

      assert component.component_id == new_child.id
    end

    test "clears all components when given empty list" do
      parent_ap = insert(:assessment_point)
      child_ap = insert(:assessment_point)

      insert(:assessment_point_component, parent: parent_ap, component: child_ap)

      assert {:ok, :replaced} =
               AssessmentComposition.replace_assessment_point_components(
                 @staff_scope,
                 parent_ap.id,
                 []
               )

      assert AssessmentComposition.list_assessment_point_components(@staff_scope, parent_ap.id) ==
               []
    end

    test "returns error changeset on invalid component attrs" do
      parent_ap = insert(:assessment_point)

      assert {:error, %Ecto.Changeset{}} =
               AssessmentComposition.replace_assessment_point_components(
                 @staff_scope,
                 parent_ap.id,
                 [
                   %{component_id: parent_ap.id, weight: 0.0}
                 ]
               )
    end

    test "rolls back all inserts when one is invalid" do
      parent_ap = insert(:assessment_point)
      child_ap = insert(:assessment_point)

      insert(:assessment_point_component, parent: parent_ap, component: child_ap)

      assert {:error, _} =
               AssessmentComposition.replace_assessment_point_components(
                 @staff_scope,
                 parent_ap.id,
                 [
                   %{component_id: child_ap.id, weight: 1.0},
                   %{component_id: child_ap.id, weight: 0.0}
                 ]
               )

      # original component must still exist (transaction rolled back)
      assert [_] =
               AssessmentComposition.list_assessment_point_components(@staff_scope, parent_ap.id)
    end

    test "raises when scope is not staff" do
      parent_ap = insert(:assessment_point)

      assert_raise MatchError, fn ->
        AssessmentComposition.replace_assessment_point_components(
          @student_scope,
          parent_ap.id,
          []
        )
      end
    end
  end

  describe "list_composed_parent_pairs/1" do
    test "returns empty list when input is empty" do
      assert AssessmentComposition.list_composed_parent_pairs([]) == []
    end

    test "returns {parent_id, student_id} pairs only for sum parents" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      ordinal_scale = insert(:scale, type: "ordinal")
      sum_parent = insert(:assessment_point, uses_composition: true, scale: scale)
      avg_parent = insert(:assessment_point, uses_composition: true, scale: ordinal_scale)

      component_ap_1 = insert(:assessment_point, scale: scale)
      component_ap_2 = insert(:assessment_point, scale: scale)

      insert(:assessment_point_component, parent: sum_parent, component: component_ap_1)
      insert(:assessment_point_component, parent: avg_parent, component: component_ap_2)

      result =
        AssessmentComposition.list_composed_parent_pairs([
          {component_ap_1.id, 1},
          {component_ap_2.id, 1}
        ])

      assert result == [{sum_parent.id, 1}]
    end

    test "fans out across students and dedups duplicate pairs" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)

      insert(:assessment_point_component, parent: parent, component: component_ap)

      pairs =
        AssessmentComposition.list_composed_parent_pairs([
          {component_ap.id, 10},
          {component_ap.id, 10},
          {component_ap.id, 20}
        ])
        |> Enum.sort()

      assert pairs == [{parent.id, 10}, {parent.id, 20}]
    end

    test "returns empty list when no component matches any sum parent" do
      assessment_point = insert(:assessment_point)

      assert AssessmentComposition.list_composed_parent_pairs([{assessment_point.id, 1}]) == []
    end
  end

  describe "recalculate_composed_entries/3" do
    setup do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap_1 = insert(:assessment_point, scale: scale)
      component_ap_2 = insert(:assessment_point, scale: scale)

      insert(:assessment_point_component, parent: parent, component: component_ap_1)
      insert(:assessment_point_component, parent: parent, component: component_ap_2)

      student = insert(:student)

      %{
        scale: scale,
        parent: parent,
        component_ap_1: component_ap_1,
        component_ap_2: component_ap_2,
        student: student
      }
    end

    test "writes the plain sum of the requested field ignoring component weights", %{
      scale: scale,
      parent: parent,
      component_ap_1: component_ap_1,
      component_ap_2: component_ap_2,
      student: student
    } do
      # set a non-default weight on one component to confirm it is ignored
      [component | _] = Repo.all(Component)
      Repo.update!(Component.changeset(component, %{weight: 3.0}))

      insert(:assessment_point_entry,
        assessment_point: component_ap_1,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 10.0
      )

      insert(:assessment_point_entry,
        assessment_point: component_ap_2,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 15.0
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :score
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      assert entry.score == 25.0
    end

    test "skips :avg parents", %{scale: scale} do
      ordinal_scale = insert(:scale, type: "ordinal")
      avg_parent = insert(:assessment_point, uses_composition: true, scale: ordinal_scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: avg_parent, component: component_ap)
      student = insert(:student)

      insert(:assessment_point_entry,
        assessment_point: component_ap,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 10.0
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{avg_parent.id, student.id}],
                 :score
               )

      refute Repo.get_by(AssessmentPointEntry,
               assessment_point_id: avg_parent.id,
               student_id: student.id
             )
    end

    test "creates a log row with the scope's profile_id", %{
      scale: scale,
      parent: parent,
      component_ap_1: component_ap_1,
      student: student
    } do
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      insert(:assessment_point_entry,
        assessment_point: component_ap_1,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 5.0
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{profile_id: profile.id},
                 [{parent.id, student.id}],
                 :score
               )

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        log =
          Repo.get_by!(AssessmentPointEntryLog,
            assessment_point_id: parent.id,
            student_id: student.id
          )

        assert log.profile_id == profile.id
        assert log.operation == "CREATE"
      end)
    end
  end
end
