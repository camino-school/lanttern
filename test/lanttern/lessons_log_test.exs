defmodule Lanttern.LessonsLogTest do
  use Lanttern.DataCase

  import Lanttern.Factory

  alias Lanttern.AuditLog
  alias Lanttern.IdentityFixtures
  alias Lanttern.Lessons.LessonLog

  describe "lesson logs" do
    test "maybe_log/5 creates log on {:ok, lesson}" do
      scope = IdentityFixtures.scope_fixture()
      strand = insert(:strand)
      lesson = insert(:lesson, strand: strand)

      result = AuditLog.maybe_log({:ok, lesson}, LessonLog, "CREATE", scope, [])

      assert {:ok, ^lesson} = result

      assert [%LessonLog{} = log] = Repo.all(LessonLog)
      assert log.lesson_id == lesson.id
      assert log.profile_id == scope.profile_id
      assert log.operation == "CREATE"
      assert log.name == lesson.name
      assert log.strand_id == strand.id
      assert log.is_ai_agent == false
    end

    test "maybe_log/5 returns {:error, changeset} unchanged" do
      scope = IdentityFixtures.scope_fixture()
      changeset = %Ecto.Changeset{}
      error_tuple = {:error, changeset}

      result = AuditLog.maybe_log(error_tuple, LessonLog, "CREATE", scope, [])

      assert result == error_tuple
      assert Repo.all(LessonLog) == []
    end

    test "maybe_log/5 skips logging when profile_id is nil" do
      scope = %Lanttern.Identity.Scope{profile_id: nil}
      lesson = insert(:lesson)

      result = AuditLog.maybe_log({:ok, lesson}, LessonLog, "CREATE", scope, [])

      assert {:ok, ^lesson} = result
      assert Repo.all(LessonLog) == []
    end

    test "maybe_log/5 respects is_ai_agent option" do
      scope = IdentityFixtures.scope_fixture()
      lesson = insert(:lesson)

      AuditLog.maybe_log({:ok, lesson}, LessonLog, "CREATE", scope, is_ai_agent: true)

      assert [%LessonLog{} = log] = Repo.all(LessonLog)
      assert log.is_ai_agent == true
    end

    test "maybe_log/5 captures subjects and tags ids" do
      scope = IdentityFixtures.scope_fixture()
      subject_a = insert(:subject)
      subject_b = insert(:subject)
      tag = insert(:lesson_tag)
      lesson = insert(:lesson, subjects: [subject_a, subject_b], tags: [tag])

      AuditLog.maybe_log({:ok, lesson}, LessonLog, "CREATE", scope, [])

      assert [%LessonLog{} = log] = Repo.all(LessonLog)
      assert Enum.sort(log.subjects_ids) == Enum.sort([subject_a.id, subject_b.id])
      assert log.tags_ids == [tag.id]
    end
  end
end
