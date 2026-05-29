defmodule Lanttern.AssessmentCompositionTest do
  use Lanttern.DataCase
  use Oban.Testing, repo: Lanttern.Repo

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

    test "returns error changeset when the component is itself a composed assessment point" do
      parent_ap = insert(:assessment_point)
      composed_ap = insert(:assessment_point, uses_composition: true)

      assert {:error, %Ecto.Changeset{} = changeset} =
               AssessmentComposition.create_assessment_point_component(@staff_scope, %{
                 parent_id: parent_ap.id,
                 component_id: composed_ap.id,
                 weight: 1.0
               })

      assert %{component_id: [_]} = errors_on(changeset)
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

    test "enqueues a recalculation job for the parent on success" do
      parent_ap = insert(:assessment_point)
      child_ap = insert(:assessment_point)

      assert {:ok, :replaced} =
               AssessmentComposition.replace_assessment_point_components(
                 @staff_scope,
                 parent_ap.id,
                 [%{component_id: child_ap.id, weight: 1.0}]
               )

      assert_enqueued(
        worker: Lanttern.Workers.CompositionRecalcWorker,
        args: %{parent_id: parent_ap.id}
      )
    end

    test "does not enqueue a recalculation job on failure" do
      parent_ap = insert(:assessment_point)

      assert {:error, %Ecto.Changeset{}} =
               AssessmentComposition.replace_assessment_point_components(
                 @staff_scope,
                 parent_ap.id,
                 [%{component_id: parent_ap.id, weight: 0.0}]
               )

      refute_enqueued(worker: Lanttern.Workers.CompositionRecalcWorker)
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

    test "returns error changeset when a component is itself a composed assessment point" do
      parent_ap = insert(:assessment_point)
      composed_ap = insert(:assessment_point, uses_composition: true)

      assert {:error, %Ecto.Changeset{} = changeset} =
               AssessmentComposition.replace_assessment_point_components(
                 @staff_scope,
                 parent_ap.id,
                 [%{component_id: composed_ap.id, weight: 1.0}]
               )

      assert %{component_id: [_]} = errors_on(changeset)
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

  describe "recalculate_all_composed_entries/2" do
    test "recalculates the composed entry for every student with component entries" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap_1 = insert(:assessment_point, scale: scale)
      component_ap_2 = insert(:assessment_point, scale: scale)

      insert(:assessment_point_component, parent: parent, component: component_ap_1)
      insert(:assessment_point_component, parent: parent, component: component_ap_2)

      student_a = insert(:student)
      student_b = insert(:student)

      insert(:assessment_point_entry,
        assessment_point: component_ap_1,
        student: student_a,
        scale: scale,
        scale_type: "numeric",
        score: 30.0
      )

      insert(:assessment_point_entry,
        assessment_point: component_ap_2,
        student: student_a,
        scale: scale,
        scale_type: "numeric",
        score: 25.0
      )

      insert(:assessment_point_entry,
        assessment_point: component_ap_1,
        student: student_b,
        scale: scale,
        scale_type: "numeric",
        score: 10.0
      )

      assert :ok = AssessmentComposition.recalculate_all_composed_entries(%Scope{}, parent.id)

      entry_a =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student_a.id
        )

      entry_b =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student_b.id
        )

      assert entry_a.score == 55.0
      assert entry_b.score == 10.0
    end

    test "recalculates teacher and student domains independently" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent, component: component_ap)

      student = insert(:student)

      insert(:assessment_point_entry,
        assessment_point: component_ap,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 40.0,
        student_score: 20.0
      )

      assert :ok = AssessmentComposition.recalculate_all_composed_entries(%Scope{}, parent.id)

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      assert entry.score == 40.0
      assert entry.student_score == 20.0
    end

    test "ignores students whose only component entry has no marking (e.g. comment-only)" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent, component: component_ap)

      marked_student = insert(:student)
      comment_only_student = insert(:student)

      insert(:assessment_point_entry,
        assessment_point: component_ap,
        student: marked_student,
        scale: scale,
        scale_type: "numeric",
        score: 30.0
      )

      # comment-only entry: no score / ordinal value, so has_marking is false
      insert(:assessment_point_entry,
        assessment_point: component_ap,
        student: comment_only_student,
        scale: scale,
        scale_type: "numeric",
        score: nil,
        report_note: "just a comment"
      )

      assert :ok = AssessmentComposition.recalculate_all_composed_entries(%Scope{}, parent.id)

      assert Repo.get_by(AssessmentPointEntry,
               assessment_point_id: parent.id,
               student_id: marked_student.id
             )

      refute Repo.get_by(AssessmentPointEntry,
               assessment_point_id: parent.id,
               student_id: comment_only_student.id
             )
    end

    test "recomputes existing parent entries when components are removed" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent = insert(:assessment_point, uses_composition: true, scale: scale)
      student = insert(:student)

      # an existing composed entry, but no components remain
      insert(:assessment_point_entry,
        assessment_point: parent,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 55.0
      )

      assert :ok = AssessmentComposition.recalculate_all_composed_entries(%Scope{}, parent.id)

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      assert is_nil(entry.score)
    end
  end

  describe "list_composed_parent_pairs/1" do
    test "returns empty list when input is empty" do
      assert AssessmentComposition.list_composed_parent_pairs([]) == []
    end

    test "returns {parent_id, student_id} pairs for both sum and avg parents" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      ordinal_scale = insert(:scale, type: "ordinal")
      sum_parent = insert(:assessment_point, uses_composition: true, scale: scale)
      avg_parent = insert(:assessment_point, uses_composition: true, scale: ordinal_scale)
      non_composed_parent = insert(:assessment_point, uses_composition: false, scale: scale)

      component_ap_1 = insert(:assessment_point, scale: scale)
      component_ap_2 = insert(:assessment_point, scale: scale)
      component_ap_3 = insert(:assessment_point, scale: scale)

      insert(:assessment_point_component, parent: sum_parent, component: component_ap_1)
      insert(:assessment_point_component, parent: avg_parent, component: component_ap_2)
      insert(:assessment_point_component, parent: non_composed_parent, component: component_ap_3)

      result =
        AssessmentComposition.list_composed_parent_pairs([
          {component_ap_1.id, 1},
          {component_ap_2.id, 1},
          {component_ap_3.id, 1}
        ])
        |> Enum.sort()

      assert result == Enum.sort([{sum_parent.id, 1}, {avg_parent.id, 1}])
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

  describe "list_composition_parent_ids/1" do
    test "returns the parents an assessment point is a component of" do
      component_ap = insert(:assessment_point)
      parent_ap_1 = insert(:assessment_point)
      parent_ap_2 = insert(:assessment_point)
      other_ap = insert(:assessment_point)

      insert(:assessment_point_component, parent: parent_ap_1, component: component_ap)
      insert(:assessment_point_component, parent: parent_ap_2, component: component_ap)
      insert(:assessment_point_component, parent: other_ap, component: insert(:assessment_point))

      assert AssessmentComposition.list_composition_parent_ids(component_ap.id) |> Enum.sort() ==
               Enum.sort([parent_ap_1.id, parent_ap_2.id])
    end

    test "returns empty list when the assessment point is not a component" do
      assessment_point = insert(:assessment_point)

      assert AssessmentComposition.list_composition_parent_ids(assessment_point.id) == []
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
                 :teacher_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      assert entry.score == 25.0
    end

    test "treats is_missing children as 0 contribution to the sum", %{
      scale: scale,
      parent: parent,
      component_ap_1: component_ap_1,
      component_ap_2: component_ap_2,
      student: student
    } do
      insert(:assessment_point_entry,
        assessment_point: component_ap_1,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 30.0
      )

      insert(:assessment_point_entry,
        assessment_point: component_ap_2,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: nil,
        is_missing: true
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :teacher_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      assert entry.score == 30.0
    end

    test "leaves the composed entry untouched when it uses manual input", %{
      scale: scale,
      parent: parent,
      component_ap_1: component_ap_1,
      student: student
    } do
      insert(:assessment_point_entry,
        assessment_point: component_ap_1,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 10.0
      )

      manual_entry =
        insert(:assessment_point_entry,
          assessment_point: parent,
          student: student,
          scale: scale,
          scale_type: "numeric",
          score: 99.0,
          use_manual_input: true
        )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :teacher_entry
               )

      reloaded = Repo.get!(AssessmentPointEntry, manual_entry.id)
      assert reloaded.score == 99.0

      # no log row is created since the entry was not touched
      refute Repo.get_by(AssessmentPointEntryLog,
               assessment_point_id: parent.id,
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
                 :teacher_entry
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

  describe "recalculate_composed_entries/3 — average-based" do
    # 5-level ordinal scale: breakpoints at .2, .4, .6, .8 → 5 ordinal values
    setup do
      ordinal_scale = insert(:scale, type: "ordinal", breakpoints: [0.2, 0.4, 0.6, 0.8])

      ov_levels =
        for {name, n} <- [{"L1", 0.0}, {"L2", 0.25}, {"L3", 0.5}, {"L4", 0.75}, {"L5", 1.0}] do
          insert(:ordinal_value, scale: ordinal_scale, name: name, normalized_value: n)
        end

      parent = insert(:assessment_point, uses_composition: true, scale: ordinal_scale)
      student = insert(:student)

      %{ordinal_scale: ordinal_scale, ov_levels: ov_levels, parent: parent, student: student}
    end

    test "computes weighted average from numeric children and writes ordinal_value_id", %{
      ordinal_scale: ordinal_scale,
      ov_levels: ov_levels,
      parent: parent,
      student: student
    } do
      numeric_scale = insert(:scale, type: "numeric", max_score: 100.0)
      child_1 = insert(:assessment_point, scale: numeric_scale)
      child_2 = insert(:assessment_point, scale: numeric_scale)

      insert(:assessment_point_component, parent: parent, component: child_1, weight: 1.0)
      insert(:assessment_point_component, parent: parent, component: child_2, weight: 3.0)

      # child_1: 80/100 = 0.8 (weight 1); child_2: 60/100 = 0.6 (weight 3)
      # weighted avg = (0.8*1 + 0.6*3) / 4 = 2.6 / 4 = 0.65 → breakpoints place at index 3 → L4
      insert(:assessment_point_entry,
        assessment_point: child_1,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 80.0
      )

      insert(:assessment_point_entry,
        assessment_point: child_2,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 60.0
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :teacher_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      expected_id = Enum.at(ov_levels, 3).id
      assert entry.ordinal_value_id == expected_id
      assert entry.scale_id == ordinal_scale.id
      assert is_nil(entry.calculation_error)
    end

    test "persists the precise normalized average alongside the ordinal value", %{
      parent: parent,
      student: student
    } do
      numeric_scale = insert(:scale, type: "numeric", max_score: 100.0)
      child_1 = insert(:assessment_point, scale: numeric_scale)
      child_2 = insert(:assessment_point, scale: numeric_scale)

      insert(:assessment_point_component, parent: parent, component: child_1, weight: 1.0)
      insert(:assessment_point_component, parent: parent, component: child_2, weight: 3.0)

      # weighted avg = (0.8*1 + 0.6*3) / 4 = 0.65
      insert(:assessment_point_entry,
        assessment_point: child_1,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 80.0
      )

      insert(:assessment_point_entry,
        assessment_point: child_2,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 60.0
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :teacher_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      assert entry.normalized_value == 0.65
      # the precise value falls within the resolved ordinal value's band, not the
      # ordinal value's representative normalized_value
      refute entry.normalized_value == entry.ordinal_value_id
    end

    test "persists student_normalized_value for the student domain", %{
      parent: parent,
      student: student
    } do
      numeric_scale = insert(:scale, type: "numeric", max_score: 100.0)
      child = insert(:assessment_point, scale: numeric_scale)
      insert(:assessment_point_component, parent: parent, component: child, weight: 1.0)

      insert(:assessment_point_entry,
        assessment_point: child,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        student_score: 70.0
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :student_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      assert entry.student_normalized_value == 0.7
      assert is_nil(entry.normalized_value)
    end

    test "a manual ordinal edit clears a previously stored normalized_value", %{
      ordinal_scale: ordinal_scale,
      ov_levels: ov_levels,
      parent: parent,
      student: student
    } do
      entry =
        insert(:assessment_point_entry,
          assessment_point: parent,
          student: student,
          scale: ordinal_scale,
          scale_type: "ordinal",
          ordinal_value: Enum.at(ov_levels, 2),
          normalized_value: 0.55
        )

      assert {:ok, updated} =
               entry
               |> AssessmentPointEntry.changeset(%{ordinal_value_id: Enum.at(ov_levels, 4).id})
               |> Repo.update()

      assert updated.ordinal_value_id == Enum.at(ov_levels, 4).id
      assert is_nil(updated.normalized_value)
    end

    test "uses ordinal child entries' normalized_value", %{
      ov_levels: ov_levels,
      parent: parent,
      student: student
    } do
      child_scale = insert(:scale, type: "ordinal", breakpoints: [0.5])
      child_low = insert(:ordinal_value, scale: child_scale, normalized_value: 0.2)
      child_high = insert(:ordinal_value, scale: child_scale, normalized_value: 0.9)

      child_1 = insert(:assessment_point, scale: child_scale)
      child_2 = insert(:assessment_point, scale: child_scale)

      insert(:assessment_point_component, parent: parent, component: child_1, weight: 1.0)
      insert(:assessment_point_component, parent: parent, component: child_2, weight: 1.0)

      insert(:assessment_point_entry,
        assessment_point: child_1,
        student: student,
        scale: child_scale,
        scale_type: "ordinal",
        ordinal_value: child_low
      )

      insert(:assessment_point_entry,
        assessment_point: child_2,
        student: student,
        scale: child_scale,
        scale_type: "ordinal",
        ordinal_value: child_high
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :teacher_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      # avg = (0.2 + 0.9) / 2 = 0.55 → index 2 → L3
      assert entry.ordinal_value_id == Enum.at(ov_levels, 2).id
    end

    test "mixes numeric and ordinal children", %{
      ov_levels: ov_levels,
      parent: parent,
      student: student
    } do
      numeric_scale = insert(:scale, type: "numeric", max_score: 10.0)
      child_ord_scale = insert(:scale, type: "ordinal", breakpoints: [0.5])
      child_ov = insert(:ordinal_value, scale: child_ord_scale, normalized_value: 1.0)

      child_num = insert(:assessment_point, scale: numeric_scale)
      child_ord = insert(:assessment_point, scale: child_ord_scale)

      insert(:assessment_point_component, parent: parent, component: child_num, weight: 1.0)
      insert(:assessment_point_component, parent: parent, component: child_ord, weight: 1.0)

      insert(:assessment_point_entry,
        assessment_point: child_num,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 4.0
      )

      insert(:assessment_point_entry,
        assessment_point: child_ord,
        student: student,
        scale: child_ord_scale,
        scale_type: "ordinal",
        ordinal_value: child_ov
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :teacher_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      # avg = (0.4 + 1.0) / 2 = 0.7 → index 3 → L4
      assert entry.ordinal_value_id == Enum.at(ov_levels, 3).id
    end

    test "skips children with nil values and computes avg over the rest", %{
      ov_levels: ov_levels,
      parent: parent,
      student: student
    } do
      numeric_scale = insert(:scale, type: "numeric", max_score: 100.0)
      child_1 = insert(:assessment_point, scale: numeric_scale)
      child_2 = insert(:assessment_point, scale: numeric_scale)

      insert(:assessment_point_component, parent: parent, component: child_1, weight: 1.0)
      insert(:assessment_point_component, parent: parent, component: child_2, weight: 1.0)

      insert(:assessment_point_entry,
        assessment_point: child_1,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 90.0
      )

      insert(:assessment_point_entry,
        assessment_point: child_2,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: nil
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :teacher_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      # avg = 0.9 → index 4 → L5
      assert entry.ordinal_value_id == Enum.at(ov_levels, 4).id
    end

    test "writes nil ordinal_value_id when no child has a value", %{
      ordinal_scale: ordinal_scale,
      ov_levels: ov_levels,
      parent: parent,
      student: student
    } do
      numeric_scale = insert(:scale, type: "numeric", max_score: 100.0)
      child = insert(:assessment_point, scale: numeric_scale)
      insert(:assessment_point_component, parent: parent, component: child, weight: 1.0)

      # pre-existing parent entry so we can assert it gets cleared
      insert(:assessment_point_entry,
        assessment_point: parent,
        student: student,
        scale: ordinal_scale,
        scale_type: "ordinal",
        ordinal_value: hd(ov_levels)
      )

      insert(:assessment_point_entry,
        assessment_point: child,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: nil
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :teacher_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      assert is_nil(entry.ordinal_value_id)
      assert is_nil(entry.calculation_error)
    end

    test "uses student_ordinal_value_id under :student_entry domain", %{
      ov_levels: ov_levels,
      parent: parent,
      student: student
    } do
      numeric_scale = insert(:scale, type: "numeric", max_score: 100.0)
      child = insert(:assessment_point, scale: numeric_scale)
      insert(:assessment_point_component, parent: parent, component: child, weight: 1.0)

      insert(:assessment_point_entry,
        assessment_point: child,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 10.0,
        student_score: 70.0
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :student_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      # 70/100 = 0.7 → index 3 → L4
      assert entry.student_ordinal_value_id == Enum.at(ov_levels, 3).id
      assert is_nil(entry.ordinal_value_id)
    end

    test "treats is_missing children as normalized 0 in the weighted average", %{
      ov_levels: ov_levels,
      parent: parent,
      student: student
    } do
      numeric_scale = insert(:scale, type: "numeric", max_score: 100.0)
      child_1 = insert(:assessment_point, scale: numeric_scale)
      child_2 = insert(:assessment_point, scale: numeric_scale)

      insert(:assessment_point_component, parent: parent, component: child_1, weight: 1.0)
      insert(:assessment_point_component, parent: parent, component: child_2, weight: 1.0)

      insert(:assessment_point_entry,
        assessment_point: child_1,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 100.0
      )

      insert(:assessment_point_entry,
        assessment_point: child_2,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: nil,
        is_missing: true
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :teacher_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      # avg = (1.0 + 0.0) / 2 = 0.5 → index 2 → L3
      assert entry.ordinal_value_id == Enum.at(ov_levels, 2).id
    end

    test "treats is_missing children as normalized 0 under :student_entry domain", %{
      ov_levels: ov_levels,
      parent: parent,
      student: student
    } do
      numeric_scale = insert(:scale, type: "numeric", max_score: 100.0)
      child_1 = insert(:assessment_point, scale: numeric_scale)
      child_2 = insert(:assessment_point, scale: numeric_scale)

      insert(:assessment_point_component, parent: parent, component: child_1, weight: 1.0)
      insert(:assessment_point_component, parent: parent, component: child_2, weight: 1.0)

      insert(:assessment_point_entry,
        assessment_point: child_1,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        student_score: 100.0
      )

      insert(:assessment_point_entry,
        assessment_point: child_2,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        student_score: nil,
        is_missing: true
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :student_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      # avg = (1.0 + 0.0) / 2 = 0.5 → index 2 → L3
      assert entry.student_ordinal_value_id == Enum.at(ov_levels, 2).id
    end

    test "flags scale_conversion_failed when breakpoints don't match ordinal values" do
      # scale with 4 breakpoints but only 2 ordinal values → conversion returns nil for high avg
      bad_scale = insert(:scale, type: "ordinal", breakpoints: [0.2, 0.4, 0.6, 0.8])
      insert(:ordinal_value, scale: bad_scale, normalized_value: 0.0, name: "low")
      insert(:ordinal_value, scale: bad_scale, normalized_value: 0.5, name: "mid")

      parent = insert(:assessment_point, uses_composition: true, scale: bad_scale)

      numeric_scale = insert(:scale, type: "numeric", max_score: 100.0)
      child = insert(:assessment_point, scale: numeric_scale)
      insert(:assessment_point_component, parent: parent, component: child, weight: 1.0)

      student = insert(:student)

      insert(:assessment_point_entry,
        assessment_point: child,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 95.0
      )

      assert :ok =
               AssessmentComposition.recalculate_composed_entries(
                 %Scope{},
                 [{parent.id, student.id}],
                 :teacher_entry
               )

      entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent.id,
          student_id: student.id
        )

      assert entry.calculation_error == "scale_conversion_failed"
      assert is_nil(entry.ordinal_value_id)
    end
  end
end
