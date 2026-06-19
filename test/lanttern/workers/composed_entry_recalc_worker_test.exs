defmodule Lanttern.Workers.ComposedEntryRecalcWorkerTest do
  use Lanttern.DataCase
  use Oban.Testing, repo: Lanttern.Repo

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Repo
  alias Lanttern.Workers.ComposedEntryRecalcWorker

  import Lanttern.Factory

  describe "perform/1" do
    test "writes the sum of the requested field into the composed entry" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap_1 = insert(:assessment_point, scale: scale)
      component_ap_2 = insert(:assessment_point, scale: scale)

      insert(:assessment_point_component, parent: parent_ap, component: component_ap_1)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap_2)

      student = insert(:student)

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
        score: 25.0
      )

      args = %{
        "pairs" => [[parent_ap.id, student.id]],
        "domain" => "teacher_entry",
        "profile_id" => nil
      }

      assert :ok = perform_job(ComposedEntryRecalcWorker, args)

      composed_entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent_ap.id,
          student_id: student.id
        )

      assert composed_entry.score == 55.0
      assert is_nil(composed_entry.calculation_error)
    end

    # The student domain is no longer enqueued automatically (composed student
    # entries surfaced in the student/guardian view as a self-assessment), but
    # the engine still supports it when invoked directly — kept ready for the
    # planned student self-assessment redesign.
    test "recalculates student_score when explicitly invoked for the student domain" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)

      insert(:assessment_point_entry,
        assessment_point: component_ap,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 10.0,
        student_score: 40.0
      )

      args = %{
        "pairs" => [[parent_ap.id, student.id]],
        "domain" => "student_entry",
        "profile_id" => nil
      }

      assert :ok = perform_job(ComposedEntryRecalcWorker, args)

      composed_entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent_ap.id,
          student_id: student.id
        )

      assert composed_entry.student_score == 40.0
      assert is_nil(composed_entry.score)
    end

    test "writes nil when all component entries are nil for the field" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)

      insert(:assessment_point_entry,
        assessment_point: parent_ap,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 42.0
      )

      insert(:assessment_point_entry,
        assessment_point: component_ap,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: nil
      )

      args = %{
        "pairs" => [[parent_ap.id, student.id]],
        "domain" => "teacher_entry",
        "profile_id" => nil
      }

      assert :ok = perform_job(ComposedEntryRecalcWorker, args)

      composed_entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent_ap.id,
          student_id: student.id
        )

      assert is_nil(composed_entry.score)
    end

    test "flags calculation_error when the recomputed value exceeds scale max_score" do
      scale = insert(:scale, type: "numeric", max_score: 50.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap_1 = insert(:assessment_point, scale: scale)
      component_ap_2 = insert(:assessment_point, scale: scale)

      insert(:assessment_point_component, parent: parent_ap, component: component_ap_1)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap_2)

      student = insert(:student)

      insert(:assessment_point_entry,
        assessment_point: component_ap_1,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 40.0
      )

      insert(:assessment_point_entry,
        assessment_point: component_ap_2,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 30.0
      )

      args = %{
        "pairs" => [[parent_ap.id, student.id]],
        "domain" => "teacher_entry",
        "profile_id" => nil
      }

      assert :ok = perform_job(ComposedEntryRecalcWorker, args)

      composed_entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent_ap.id,
          student_id: student.id
        )

      assert composed_entry.calculation_error == "max_score_overflow"
      assert is_nil(composed_entry.score)
    end

    test "clears a previously set calculation_error once the sum fits again" do
      scale = insert(:scale, type: "numeric", max_score: 50.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)

      insert(:assessment_point_entry,
        assessment_point: parent_ap,
        student: student,
        scale: scale,
        scale_type: "numeric",
        calculation_error: "max_score_overflow"
      )

      insert(:assessment_point_entry,
        assessment_point: component_ap,
        student: student,
        scale: scale,
        scale_type: "numeric",
        score: 20.0
      )

      args = %{
        "pairs" => [[parent_ap.id, student.id]],
        "domain" => "teacher_entry",
        "profile_id" => nil
      }

      assert :ok = perform_job(ComposedEntryRecalcWorker, args)

      composed_entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent_ap.id,
          student_id: student.id
        )

      assert composed_entry.score == 20.0
      assert is_nil(composed_entry.calculation_error)
    end

    test "writes ordinal_value_id for avg (ordinal-parent) compositions" do
      ordinal_scale = insert(:scale, type: "ordinal", breakpoints: [0.5])
      low = insert(:ordinal_value, scale: ordinal_scale, normalized_value: 0.0, name: "low")
      _high = insert(:ordinal_value, scale: ordinal_scale, normalized_value: 1.0, name: "high")

      numeric_scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: ordinal_scale)
      component_ap = insert(:assessment_point, scale: numeric_scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)

      insert(:assessment_point_entry,
        assessment_point: component_ap,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 30.0
      )

      args = %{
        "pairs" => [[parent_ap.id, student.id]],
        "domain" => "teacher_entry",
        "profile_id" => nil
      }

      assert :ok = perform_job(ComposedEntryRecalcWorker, args)

      composed_entry =
        Repo.get_by!(AssessmentPointEntry,
          assessment_point_id: parent_ap.id,
          student_id: student.id
        )

      assert composed_entry.ordinal_value_id == low.id
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

      args = %{
        "pairs" => [[parent_ap.id, student.id]],
        "domain" => "teacher_entry",
        "profile_id" => nil
      }

      assert :ok = perform_job(ComposedEntryRecalcWorker, args)

      refute Repo.get_by(AssessmentPointEntry,
               assessment_point_id: parent_ap.id,
               student_id: student.id
             )
    end
  end
end
