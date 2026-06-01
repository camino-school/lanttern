defmodule Lanttern.Workers.CompositionRecalcWorkerTest do
  use Lanttern.DataCase
  use Oban.Testing, repo: Lanttern.Repo

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Repo
  alias Lanttern.Workers.CompositionRecalcWorker

  import Lanttern.Factory

  describe "perform/1" do
    test "recalculates the composed entries for every affected student" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap_1 = insert(:assessment_point, scale: scale)
      component_ap_2 = insert(:assessment_point, scale: scale)

      insert(:assessment_point_component, parent: parent_ap, component: component_ap_1)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap_2)

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

      args = %{"parent_id" => parent_ap.id, "profile_id" => nil}

      assert :ok = perform_job(CompositionRecalcWorker, args)

      entry_a =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent_ap.id,
          student_id: student_a.id
        )

      entry_b =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent_ap.id,
          student_id: student_b.id
        )

      assert entry_a.score == 55.0
      assert entry_b.score == 10.0
    end

    test "skips parents that don't use composition" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent_ap = insert(:assessment_point, uses_composition: false, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)

      insert(:assessment_point_entry,
        assessment_point: component_ap,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 30.0
      )

      args = %{"parent_id" => parent_ap.id, "profile_id" => nil}

      assert :ok = perform_job(CompositionRecalcWorker, args)

      refute Repo.get_by(AssessmentPointEntry,
               assessment_point_id: parent_ap.id,
               student_id: student.id
             )
    end
  end
end
