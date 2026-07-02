defmodule Lanttern.LessonsTest do
  use Lanttern.DataCase

  import Lanttern.Factory

  alias Lanttern.IdentityFixtures
  alias Lanttern.Repo

  alias Lanttern.Lessons

  describe "lessons" do
    alias Lanttern.Lessons.Lesson

    @invalid_attrs %{name: nil, description: nil}

    defp scope_fixture_for_lessons do
      IdentityFixtures.scope_fixture()
    end

    test "list_lessons/0 returns all lessons" do
      lesson = insert(:lesson)
      [expected] = Lessons.list_lessons()
      assert expected.id == lesson.id
    end

    test "list_lessons/1 with strand_id option filters lessons by strand" do
      strand_a = insert(:strand)
      strand_b = insert(:strand)

      lesson_a1 = insert(:lesson, strand: strand_a, name: "Lesson A1")
      lesson_a2 = insert(:lesson, strand: strand_a, name: "Lesson A2")
      lesson_b1 = insert(:lesson, strand: strand_b, name: "Lesson B1")

      # Filter by strand A
      lessons_a = Lessons.list_lessons(strand_id: strand_a.id)
      assert length(lessons_a) == 2
      assert Enum.all?(lessons_a, &(&1.strand_id == strand_a.id))
      lesson_ids_a = Enum.map(lessons_a, & &1.id)
      assert lesson_a1.id in lesson_ids_a
      assert lesson_a2.id in lesson_ids_a

      # Filter by strand B
      lessons_b = Lessons.list_lessons(strand_id: strand_b.id)
      assert [lesson] = lessons_b
      assert lesson.id == lesson_b1.id
      assert lesson.strand_id == strand_b.id
    end

    test "list_lessons/1 with subjects_ids option filters lessons by subjects" do
      subject_a = insert(:subject)
      subject_b = insert(:subject)
      subject_c = insert(:subject)

      lesson_1 = insert(:lesson, subjects: [subject_a], name: "Lesson 1")
      lesson_2 = insert(:lesson, subjects: [subject_a, subject_b], name: "Lesson 2")
      lesson_3 = insert(:lesson, subjects: [subject_b, subject_c], name: "Lesson 3")
      lesson_4 = insert(:lesson, subjects: [subject_c], name: "Lesson 4")

      # Filter by subject A - should return lessons 1 and 2
      assert [result_1, result_2] = Lessons.list_lessons(subjects_ids: [subject_a.id])
      assert result_1.id == lesson_1.id
      assert result_2.id == lesson_2.id

      # Filter by subject B - should return lessons 2 and 3
      assert [result_1, result_2] = Lessons.list_lessons(subjects_ids: [subject_b.id])
      assert result_1.id == lesson_2.id
      assert result_2.id == lesson_3.id

      # Filter by subjects A and C - should return lessons 1, 2, 3, and 4
      assert [result_1, result_2, result_3, result_4] =
               Lessons.list_lessons(subjects_ids: [subject_a.id, subject_c.id])

      assert result_1.id == lesson_1.id
      assert result_2.id == lesson_2.id
      assert result_3.id == lesson_3.id
      assert result_4.id == lesson_4.id
    end

    test "list_lessons/1 with empty subjects_ids ignores filter" do
      lesson_1 = insert(:lesson, subjects: [insert(:subject)])
      lesson_2 = insert(:lesson, subjects: [insert(:subject)])

      assert [result_1, result_2] = Lessons.list_lessons(subjects_ids: [])
      assert result_1.id == lesson_1.id
      assert result_2.id == lesson_2.id
    end

    test "list_lessons/1 with strand_id and subjects_ids filters by both" do
      strand_a = insert(:strand)
      strand_b = insert(:strand)
      subject_a = insert(:subject)
      subject_b = insert(:subject)

      lesson_a_1 = insert(:lesson, strand: strand_a, subjects: [subject_a])
      lesson_a_2 = insert(:lesson, strand: strand_a, subjects: [subject_b])
      _lesson_b_1 = insert(:lesson, strand: strand_b, subjects: [subject_a])
      _lesson_b_2 = insert(:lesson, strand: strand_b, subjects: [subject_b])

      # Filter by strand A and subject A - should return only lesson_a_1
      lessons = Lessons.list_lessons(strand_id: strand_a.id, subjects_ids: [subject_a.id])
      assert [lesson] = lessons
      assert lesson.id == lesson_a_1.id

      # Filter by strand A and subject B - should return only lesson_a_2
      lessons = Lessons.list_lessons(strand_id: strand_a.id, subjects_ids: [subject_b.id])
      assert [lesson] = lessons
      assert lesson.id == lesson_a_2.id
    end

    test "get_lesson!/1 returns the lesson with given id" do
      lesson = insert(:lesson)
      expected = Lessons.get_lesson!(lesson.id)
      assert expected.id == lesson.id
    end

    test "get_lesson/2 with preloads option returns lesson with preloaded subjects" do
      subject_a = insert(:subject)
      subject_b = insert(:subject)
      lesson = insert(:lesson, subjects: [subject_a, subject_b])

      result = Lessons.get_lesson(lesson.id, preloads: :subjects)

      assert result.id == lesson.id
      assert [subj1, subj2] = result.subjects
      subject_ids = [subj1.id, subj2.id]
      assert subject_a.id in subject_ids
      assert subject_b.id in subject_ids
    end

    test "get_lesson/2 returns nil when lesson does not exist" do
      assert Lessons.get_lesson(0) == nil
    end

    test "get_lesson!/2 with preloads option returns lesson with preloaded subjects" do
      subject_a = insert(:subject)
      subject_b = insert(:subject)
      lesson = insert(:lesson, subjects: [subject_a, subject_b])

      result = Lessons.get_lesson!(lesson.id, preloads: :subjects)

      assert result.id == lesson.id
      assert [subj1, subj2] = result.subjects
      subject_ids = [subj1.id, subj2.id]
      assert subject_a.id in subject_ids
      assert subject_b.id in subject_ids
    end

    test "get_lesson!/2 raises when lesson does not exist" do
      assert_raise Ecto.NoResultsError, fn -> Lessons.get_lesson!(0) end
    end

    test "create_lesson/2 with valid data creates a lesson" do
      scope = scope_fixture_for_lessons()
      strand = insert(:strand)
      valid_attrs = %{name: "some name", description: "some description", strand_id: strand.id}

      assert {:ok, %Lesson{} = lesson} = Lessons.create_lesson(scope, valid_attrs)
      assert lesson.name == "some name"
      assert lesson.description == "some description"
      assert lesson.strand_id == strand.id
    end

    test "create_lesson/2 with invalid data returns error changeset" do
      scope = scope_fixture_for_lessons()
      assert {:error, %Ecto.Changeset{}} = Lessons.create_lesson(scope, @invalid_attrs)
    end

    test "update_lesson/3 with valid data updates the lesson" do
      scope = scope_fixture_for_lessons()
      lesson = insert(:lesson)
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Lesson{} = lesson} = Lessons.update_lesson(scope, lesson, update_attrs)
      assert lesson.name == "some updated name"
      assert lesson.description == "some updated description"
    end

    test "update_lesson/3 with invalid data returns error changeset" do
      scope = scope_fixture_for_lessons()
      lesson = insert(:lesson)
      assert {:error, %Ecto.Changeset{}} = Lessons.update_lesson(scope, lesson, @invalid_attrs)
      expected = Lessons.get_lesson!(lesson.id)
      assert expected.name == lesson.name
      assert expected.description == lesson.description
    end

    test "update_lessons_positions/2 update lessons position based on list order" do
      scope = scope_fixture_for_lessons()
      strand = insert(:strand)
      lesson_1 = insert(:lesson, strand: strand)
      lesson_2 = insert(:lesson, strand: strand)
      lesson_3 = insert(:lesson, strand: strand)
      lesson_4 = insert(:lesson, strand: strand)

      sorted_lessons_ids =
        [
          lesson_2.id,
          lesson_3.id,
          lesson_1.id,
          lesson_4.id
        ]

      :ok = Lessons.update_lessons_positions(scope, sorted_lessons_ids)

      [expected_2, expected_3, expected_1, expected_4] =
        Lessons.list_lessons(strand_id: strand.id)

      assert expected_1.id == lesson_1.id
      assert expected_2.id == lesson_2.id
      assert expected_3.id == lesson_3.id
      assert expected_4.id == lesson_4.id
    end

    test "delete_lesson/2 deletes the lesson" do
      scope = scope_fixture_for_lessons()
      lesson = insert(:lesson)
      assert {:ok, %Lesson{}} = Lessons.delete_lesson(scope, lesson)
      assert_raise Ecto.NoResultsError, fn -> Lessons.get_lesson!(lesson.id) end
    end

    test "change_lesson/2 returns a lesson changeset" do
      scope = scope_fixture_for_lessons()
      lesson = insert(:lesson)
      assert %Ecto.Changeset{} = Lessons.change_lesson(scope, lesson)
    end

    test "update_lessons_positions/2 raises when scope is not staff" do
      scope = IdentityFixtures.student_scope_fixture()
      lesson = insert(:lesson)

      assert_raise MatchError, fn ->
        Lessons.update_lessons_positions(scope, [lesson.id])
      end
    end

    test "create_lesson/2 raises when scope is not staff" do
      scope = IdentityFixtures.student_scope_fixture()
      strand = insert(:strand)

      assert_raise MatchError, fn ->
        Lessons.create_lesson(scope, %{name: "Lesson", strand_id: strand.id})
      end
    end

    test "update_lesson/3 raises when scope is not staff" do
      scope = IdentityFixtures.student_scope_fixture()
      lesson = insert(:lesson)

      assert_raise MatchError, fn ->
        Lessons.update_lesson(scope, lesson, %{name: "Updated"})
      end
    end

    test "delete_lesson/2 raises when scope is not staff" do
      scope = IdentityFixtures.student_scope_fixture()
      lesson = insert(:lesson)

      assert_raise MatchError, fn ->
        Lessons.delete_lesson(scope, lesson)
      end
    end

    test "change_lesson/2 raises when scope is not staff" do
      scope = IdentityFixtures.student_scope_fixture()
      lesson = insert(:lesson)

      assert_raise MatchError, fn ->
        Lessons.change_lesson(scope, lesson)
      end
    end

    test "create_lesson/2 auto-calculates position scoped to strand and moment" do
      scope = scope_fixture_for_lessons()
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)

      assert {:ok, lesson1} =
               Lessons.create_lesson(scope, %{
                 name: "Lesson 1",
                 strand_id: strand.id,
                 moment_id: moment.id
               })

      assert {:ok, lesson2} =
               Lessons.create_lesson(scope, %{
                 name: "Lesson 2",
                 strand_id: strand.id,
                 moment_id: moment.id
               })

      assert lesson1.position == 0
      assert lesson2.position == 1
    end

    test "strand-level lessons have independent positions from moment lessons" do
      scope = scope_fixture_for_lessons()
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)

      # Create lesson in moment
      assert {:ok, moment_lesson} =
               Lessons.create_lesson(scope, %{
                 name: "Moment Lesson",
                 strand_id: strand.id,
                 moment_id: moment.id
               })

      # Create strand-level lesson
      assert {:ok, strand_lesson} =
               Lessons.create_lesson(scope, %{
                 name: "Strand Lesson",
                 strand_id: strand.id,
                 moment_id: nil
               })

      # Both start at 0 (independent sequences)
      assert moment_lesson.position == 0
      assert strand_lesson.position == 0
    end

    test "lessons in different moments have independent positions" do
      scope = scope_fixture_for_lessons()
      strand = insert(:strand)
      moment_a = insert(:moment, strand: strand, name: "Moment A")
      moment_b = insert(:moment, strand: strand, name: "Moment B")

      # Create lesson in moment A
      assert {:ok, lesson_a1} =
               Lessons.create_lesson(scope, %{
                 name: "Lesson A1",
                 strand_id: strand.id,
                 moment_id: moment_a.id
               })

      # Create lesson in moment B
      assert {:ok, lesson_b1} =
               Lessons.create_lesson(scope, %{
                 name: "Lesson B1",
                 strand_id: strand.id,
                 moment_id: moment_b.id
               })

      # Both should have position 0 (independent sequences)
      assert lesson_a1.position == 0
      assert lesson_b1.position == 0

      # Create another lesson in moment A
      assert {:ok, lesson_a2} =
               Lessons.create_lesson(scope, %{
                 name: "Lesson A2",
                 strand_id: strand.id,
                 moment_id: moment_a.id
               })

      # Should have position 1 in moment A's sequence
      assert lesson_a2.position == 1
    end

    test "create_lesson/2 respects explicitly provided position" do
      scope = scope_fixture_for_lessons()
      strand = insert(:strand)

      assert {:ok, lesson} =
               Lessons.create_lesson(scope, %{
                 name: "Lesson",
                 strand_id: strand.id,
                 position: 99
               })

      assert lesson.position == 99
    end

    test "create_lesson/2 with subjects_ids creates lesson with subjects" do
      scope = scope_fixture_for_lessons()
      strand = insert(:strand)
      subject_a = insert(:subject)
      subject_b = insert(:subject)

      assert {:ok, %Lesson{} = lesson} =
               Lessons.create_lesson(scope, %{
                 name: "Lesson with subjects",
                 strand_id: strand.id,
                 subjects_ids: [subject_a.id, subject_b.id]
               })

      lesson = Repo.preload(lesson, :subjects)
      assert [subj1, subj2] = lesson.subjects
      subject_ids = [subj1.id, subj2.id]
      assert subject_a.id in subject_ids
      assert subject_b.id in subject_ids
    end

    test "create_lesson/2 with is_published true requires description" do
      scope = scope_fixture_for_lessons()
      strand = insert(:strand)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Lessons.create_lesson(scope, %{
                 name: "Published lesson",
                 strand_id: strand.id,
                 is_published: true
               })

      assert %{description: ["Description can't be blank when lesson is published"]} =
               errors_on(changeset)
    end

    test "create_lesson/2 with is_published true and blank description returns error" do
      scope = scope_fixture_for_lessons()
      strand = insert(:strand)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Lessons.create_lesson(scope, %{
                 name: "Published lesson",
                 description: "   ",
                 strand_id: strand.id,
                 is_published: true
               })

      assert %{description: ["Description can't be blank when lesson is published"]} =
               errors_on(changeset)
    end

    test "create_lesson/2 with is_published true and description succeeds" do
      scope = scope_fixture_for_lessons()
      strand = insert(:strand)

      assert {:ok, %Lesson{} = lesson} =
               Lessons.create_lesson(scope, %{
                 name: "Published lesson",
                 description: "A valid description",
                 strand_id: strand.id,
                 is_published: true
               })

      assert lesson.is_published == true
      assert lesson.description == "A valid description"
    end

    test "create_lesson/2 with is_published false allows nil description" do
      scope = scope_fixture_for_lessons()
      strand = insert(:strand)

      assert {:ok, %Lesson{} = lesson} =
               Lessons.create_lesson(scope, %{
                 name: "Draft lesson",
                 strand_id: strand.id,
                 is_published: false
               })

      assert lesson.is_published == false
      assert lesson.description == nil
    end

    test "update_lesson/3 with subjects_ids updates lesson subjects" do
      scope = scope_fixture_for_lessons()
      lesson = insert(:lesson) |> Repo.preload(:subjects)
      subject_a = insert(:subject)
      subject_b = insert(:subject)
      subject_c = insert(:subject)

      # Add initial subjects
      assert {:ok, lesson} =
               Lessons.update_lesson(scope, lesson, %{
                 subjects_ids: [subject_a.id, subject_b.id]
               })

      lesson = Repo.preload(lesson, :subjects, force: true)
      assert [_, _] = lesson.subjects

      # Update subjects (replace with different set)
      assert {:ok, lesson} =
               Lessons.update_lesson(scope, lesson, %{
                 subjects_ids: [subject_b.id, subject_c.id]
               })

      lesson = Repo.preload(lesson, :subjects, force: true)
      assert [subj1, subj2] = lesson.subjects
      subject_ids = [subj1.id, subj2.id]
      assert subject_b.id in subject_ids
      assert subject_c.id in subject_ids
      refute subject_a.id in subject_ids
    end

    test "update_lesson/3 with empty subjects_ids removes all subjects" do
      scope = scope_fixture_for_lessons()
      lesson = insert(:lesson) |> Repo.preload(:subjects)
      subject_a = insert(:subject)
      subject_b = insert(:subject)

      # Add subjects
      assert {:ok, lesson} =
               Lessons.update_lesson(scope, lesson, %{
                 subjects_ids: [subject_a.id, subject_b.id]
               })

      lesson = Repo.preload(lesson, :subjects, force: true)
      assert [_, _] = lesson.subjects

      # Remove all subjects
      assert {:ok, lesson} = Lessons.update_lesson(scope, lesson, %{subjects_ids: []})

      lesson = Repo.preload(lesson, :subjects, force: true)
      assert lesson.subjects == []
    end

    test "update_lesson/3 setting is_published to true requires description" do
      scope = scope_fixture_for_lessons()
      lesson = insert(:lesson, is_published: false, description: nil)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Lessons.update_lesson(scope, lesson, %{is_published: true})

      assert %{description: ["Description can't be blank when lesson is published"]} =
               errors_on(changeset)
    end

    test "update_lesson/3 can publish lesson with description" do
      scope = scope_fixture_for_lessons()
      lesson = insert(:lesson, is_published: false, description: "Some description")

      assert {:ok, %Lesson{} = updated_lesson} =
               Lessons.update_lesson(scope, lesson, %{is_published: true})

      assert updated_lesson.is_published == true
      assert updated_lesson.description == "Some description"
    end

    test "update_lesson/3 can unpublish lesson without description" do
      scope = scope_fixture_for_lessons()
      lesson = insert(:lesson, is_published: true, description: "Some description")

      assert {:ok, %Lesson{} = updated_lesson} =
               Lessons.update_lesson(scope, lesson, %{is_published: false, description: nil})

      assert updated_lesson.is_published == false
      assert updated_lesson.description == nil
    end
  end

  describe "lesson attachments" do
    alias Lanttern.Attachments
    alias Lanttern.Lessons.LessonAttachment

    test "create_lesson_attachment/4 creates attachment linked to lesson with is_teacher_only true when teacher-only" do
      profile = insert(:profile)
      lesson = insert(:lesson)

      {:ok, attachment} =
        Lessons.create_lesson_attachment(
          profile.id,
          lesson.id,
          %{"name" => "teacher doc", "link" => "https://example.com", "is_external" => true},
          true
        )

      assert attachment.is_teacher_only == true
    end

    test "create_lesson_attachment/4 creates attachment linked to lesson with is_teacher_only false when not teacher-only" do
      profile = insert(:profile)
      lesson = insert(:lesson)

      {:ok, attachment} =
        Lessons.create_lesson_attachment(
          profile.id,
          lesson.id,
          %{"name" => "student doc", "link" => "https://example.com", "is_external" => true},
          false
        )

      assert attachment.is_teacher_only == false
    end

    test "create_lesson_attachment/4 sets position automatically" do
      profile = insert(:profile)
      lesson = insert(:lesson)

      {:ok, attachment_1} =
        Lessons.create_lesson_attachment(
          profile.id,
          lesson.id,
          %{"name" => "doc 1", "link" => "https://example.com", "is_external" => true}
        )

      {:ok, attachment_2} =
        Lessons.create_lesson_attachment(
          profile.id,
          lesson.id,
          %{"name" => "doc 2", "link" => "https://example.com", "is_external" => true}
        )

      lesson_attachment_1 =
        Repo.get_by!(LessonAttachment, attachment_id: attachment_1.id)

      lesson_attachment_2 =
        Repo.get_by!(LessonAttachment, attachment_id: attachment_2.id)

      assert lesson_attachment_1.position == 0
      assert lesson_attachment_2.position == 1
    end

    test "update_lesson_attachments_positions/1 updates positions" do
      lesson = insert(:lesson)
      profile = insert(:profile)

      {:ok, attachment_1} =
        Lessons.create_lesson_attachment(
          profile.id,
          lesson.id,
          %{"name" => "doc 1", "link" => "https://example.com", "is_external" => true}
        )

      {:ok, attachment_2} =
        Lessons.create_lesson_attachment(
          profile.id,
          lesson.id,
          %{"name" => "doc 2", "link" => "https://example.com", "is_external" => true}
        )

      {:ok, attachment_3} =
        Lessons.create_lesson_attachment(
          profile.id,
          lesson.id,
          %{"name" => "doc 3", "link" => "https://example.com", "is_external" => true}
        )

      # reorder: 3, 1, 2
      :ok =
        Lessons.update_lesson_attachments_positions([
          attachment_3.id,
          attachment_1.id,
          attachment_2.id
        ])

      # verify order via list_attachments
      [expected_1, expected_2, expected_3] =
        Attachments.list_attachments(lesson_id: lesson.id)

      assert expected_1.id == attachment_3.id
      assert expected_2.id == attachment_1.id
      assert expected_3.id == attachment_2.id
    end

    test "toggle_lesson_attachment_share/1 toggles is_teacher_only_resource and returns correct is_teacher_only" do
      profile = insert(:profile)
      lesson = insert(:lesson)

      {:ok, attachment} =
        Lessons.create_lesson_attachment(
          profile.id,
          lesson.id,
          %{"name" => "doc", "link" => "https://example.com", "is_external" => true},
          true
        )

      assert attachment.is_teacher_only == true

      {:ok, toggled_attachment} = Lessons.toggle_lesson_attachment_share(attachment)
      assert toggled_attachment.is_teacher_only == false

      # verify in database
      lesson_attachment = Repo.get_by!(LessonAttachment, attachment_id: attachment.id)
      assert lesson_attachment.is_teacher_only_resource == false
    end
  end

  describe "lesson_tags" do
    alias Lanttern.IdentityFixtures
    alias Lanttern.Lessons.Tag

    @invalid_attrs %{name: nil, position: nil, text_color: nil, bg_color: nil}

    defp create_tag_with_scope do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      school = Lanttern.Schools.get_school!(scope.school_id)
      tag = insert(:lesson_tag, school: school)
      {scope, tag}
    end

    test "list_lesson_tags/1 returns all scoped lesson_tags" do
      {scope, tag} = create_tag_with_scope()
      {other_scope, other_tag} = create_tag_with_scope()

      assert [result] = Lessons.list_lesson_tags(scope)
      assert result.id == tag.id

      assert [other_result] = Lessons.list_lesson_tags(other_scope)
      assert other_result.id == other_tag.id
    end

    test "get_tag!/2 returns the tag with given id" do
      {scope, tag} = create_tag_with_scope()
      {other_scope, _other_tag} = create_tag_with_scope()

      assert Lessons.get_tag!(scope, tag.id).id == tag.id
      assert_raise Ecto.NoResultsError, fn -> Lessons.get_tag!(other_scope, tag.id) end
    end

    test "create_tag/2 with valid data creates a tag" do
      valid_attrs = %{
        name: "some name",
        position: 42,
        text_color: "#112233",
        bg_color: "#aabbcc"
      }

      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})

      assert {:ok, %Tag{} = tag} = Lessons.create_tag(scope, valid_attrs)
      assert tag.name == "some name"
      assert tag.position == 42
      assert tag.text_color == "#112233"
      assert tag.bg_color == "#aabbcc"
      assert tag.school_id == scope.school_id
    end

    test "create_tag/2 with invalid data returns error changeset" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      assert {:error, %Ecto.Changeset{}} = Lessons.create_tag(scope, @invalid_attrs)
    end

    test "create_tag/2 auto-calculates position when not provided" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})

      attrs = %{name: "Tag 1", text_color: "#000000", bg_color: "#ffffff"}

      assert {:ok, %Tag{} = tag1} = Lessons.create_tag(scope, attrs)
      assert tag1.position == 0

      assert {:ok, %Tag{} = tag2} = Lessons.create_tag(scope, %{attrs | name: "Tag 2"})
      assert tag2.position == 1

      assert {:ok, %Tag{} = tag3} = Lessons.create_tag(scope, %{attrs | name: "Tag 3"})
      assert tag3.position == 2
    end

    test "create_tag/2 respects explicitly provided position" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})

      attrs = %{name: "Tag", text_color: "#000000", bg_color: "#ffffff", position: 99}

      assert {:ok, %Tag{} = tag} = Lessons.create_tag(scope, attrs)
      assert tag.position == 99
    end

    test "create_tag/2 calculates position independently per school" do
      scope_a = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})
      scope_b = IdentityFixtures.scope_fixture(%{permissions: ["content_management"]})

      attrs = %{name: "Tag", text_color: "#000000", bg_color: "#ffffff"}

      # Create tags in school A
      assert {:ok, %Tag{} = tag_a1} = Lessons.create_tag(scope_a, attrs)
      assert {:ok, %Tag{} = tag_a2} = Lessons.create_tag(scope_a, attrs)

      # Create tag in school B
      assert {:ok, %Tag{} = tag_b1} = Lessons.create_tag(scope_b, attrs)

      # Positions are independent per school
      assert tag_a1.position == 0
      assert tag_a2.position == 1
      assert tag_b1.position == 0
    end

    test "update_tag/3 with valid data updates the tag" do
      {scope, tag} = create_tag_with_scope()

      update_attrs = %{
        name: "some updated name",
        position: 43,
        text_color: "#445566",
        bg_color: "#ddeeff"
      }

      assert {:ok, %Tag{} = updated_tag} = Lessons.update_tag(scope, tag, update_attrs)
      assert updated_tag.name == "some updated name"
      assert updated_tag.position == 43
      assert updated_tag.text_color == "#445566"
      assert updated_tag.bg_color == "#ddeeff"
    end

    test "update_tag/3 with invalid scope raises" do
      {scope, tag} = create_tag_with_scope()
      {other_scope, _other_tag} = create_tag_with_scope()

      assert scope.school_id != other_scope.school_id

      assert_raise MatchError, fn ->
        Lessons.update_tag(other_scope, tag, %{})
      end
    end

    test "update_tag/3 with invalid data returns error changeset" do
      {scope, tag} = create_tag_with_scope()
      assert {:error, %Ecto.Changeset{}} = Lessons.update_tag(scope, tag, @invalid_attrs)
      assert Lessons.get_tag!(scope, tag.id).id == tag.id
    end

    test "delete_tag/2 deletes the tag" do
      {scope, tag} = create_tag_with_scope()
      assert {:ok, %Tag{}} = Lessons.delete_tag(scope, tag)
      assert_raise Ecto.NoResultsError, fn -> Lessons.get_tag!(scope, tag.id) end
    end

    test "delete_tag/2 with invalid scope raises" do
      {scope, tag} = create_tag_with_scope()
      {other_scope, _other_tag} = create_tag_with_scope()

      assert scope.school_id != other_scope.school_id
      assert_raise MatchError, fn -> Lessons.delete_tag(other_scope, tag) end
    end

    test "change_tag/2 returns a tag changeset" do
      {scope, tag} = create_tag_with_scope()
      assert %Ecto.Changeset{} = Lessons.change_tag(scope, tag)
    end
  end

  describe "lesson_curriculum_items" do
    alias Lanttern.Lessons.LessonCurriculumItem

    import Lanttern.IdentityFixtures, only: [staff_scope_fixture: 0]

    @invalid_attrs %{position: nil}

    test "list_lesson_curriculum_items/2 returns lesson_curriculum_items for given lesson" do
      scope = staff_scope_fixture()
      %{id: id, lesson_id: lesson_id} = insert(:lesson_curriculum_item)
      insert(:lesson_curriculum_item)

      assert [%LessonCurriculumItem{id: ^id}] =
               Lessons.list_lesson_curriculum_items(scope, lesson_id)
    end

    test "get_lesson_curriculum_item!/2 returns the lesson_curriculum_item with given id" do
      scope = staff_scope_fixture()
      %{id: id} = insert(:lesson_curriculum_item)
      assert %LessonCurriculumItem{id: ^id} = Lessons.get_lesson_curriculum_item!(scope, id)
    end

    test "create_lesson_curriculum_item/2 with valid data creates a lesson_curriculum_item" do
      scope = staff_scope_fixture()
      lesson = insert(:lesson)
      curriculum_item = insert(:curriculum_item)
      valid_attrs = %{position: 42, lesson_id: lesson.id, curriculum_item_id: curriculum_item.id}

      assert {:ok, %LessonCurriculumItem{position: 42}} =
               Lessons.create_lesson_curriculum_item(scope, valid_attrs)
    end

    test "create_lesson_curriculum_item/2 with invalid data returns error changeset" do
      scope = staff_scope_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Lessons.create_lesson_curriculum_item(scope, @invalid_attrs)
    end

    test "create_lesson_curriculum_item/2 raises when scope is not staff" do
      scope = %Lanttern.Identity.Scope{profile_type: "student"}
      assert_raise MatchError, fn -> Lessons.create_lesson_curriculum_item(scope, %{}) end
    end

    test "update_lesson_curriculum_item/3 with valid data updates the lesson_curriculum_item" do
      scope = staff_scope_fixture()
      lesson_curriculum_item = insert(:lesson_curriculum_item)

      assert {:ok, %LessonCurriculumItem{position: 43}} =
               Lessons.update_lesson_curriculum_item(scope, lesson_curriculum_item, %{
                 position: 43
               })
    end

    test "update_lesson_curriculum_item/3 with invalid data returns error changeset" do
      scope = staff_scope_fixture()
      %{id: id} = lesson_curriculum_item = insert(:lesson_curriculum_item)

      assert {:error, %Ecto.Changeset{}} =
               Lessons.update_lesson_curriculum_item(
                 scope,
                 lesson_curriculum_item,
                 @invalid_attrs
               )

      assert %LessonCurriculumItem{id: ^id} = Lessons.get_lesson_curriculum_item!(scope, id)
    end

    test "update_lesson_curriculum_item/3 raises when scope is not staff" do
      scope = %Lanttern.Identity.Scope{profile_type: "student"}
      lesson_curriculum_item = insert(:lesson_curriculum_item)

      assert_raise MatchError, fn ->
        Lessons.update_lesson_curriculum_item(scope, lesson_curriculum_item, %{})
      end
    end

    test "delete_lesson_curriculum_item/2 deletes the lesson_curriculum_item" do
      scope = staff_scope_fixture()
      %{id: id} = lesson_curriculum_item = insert(:lesson_curriculum_item)

      assert {:ok, %LessonCurriculumItem{id: ^id}} =
               Lessons.delete_lesson_curriculum_item(scope, lesson_curriculum_item)

      assert_raise Ecto.NoResultsError, fn ->
        Lessons.get_lesson_curriculum_item!(scope, id)
      end
    end

    test "delete_lesson_curriculum_item/2 raises when scope is not staff" do
      scope = %Lanttern.Identity.Scope{profile_type: "student"}
      lesson_curriculum_item = insert(:lesson_curriculum_item)

      assert_raise MatchError, fn ->
        Lessons.delete_lesson_curriculum_item(scope, lesson_curriculum_item)
      end
    end

    test "change_lesson_curriculum_item/2 returns a lesson_curriculum_item changeset" do
      scope = staff_scope_fixture()
      lesson_curriculum_item = insert(:lesson_curriculum_item)

      assert %Ecto.Changeset{} =
               Lessons.change_lesson_curriculum_item(scope, lesson_curriculum_item)
    end
  end

  describe "lesson assessment point links" do
    import Lanttern.IdentityFixtures, only: [staff_scope_fixture: 0]

    alias Lanttern.Lessons.Lesson
    alias Lanttern.Lessons.LessonLog

    defp linked_pairs do
      Repo.all(
        from(apl in "assessment_points_lessons",
          select: {apl.assessment_point_id, apl.lesson_id}
        )
      )
    end

    test "link_assessment_point_to_lesson/3 links the pair and logs the snapshot" do
      scope = staff_scope_fixture()
      strand = insert(:strand)
      lesson = insert(:lesson, strand: strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, moment: moment)

      assert {:ok, %Lesson{}} =
               Lessons.link_assessment_point_to_lesson(scope, ap.id, lesson.id)

      assert [{ap_id, lesson_id}] = linked_pairs()
      assert ap_id == ap.id
      assert lesson_id == lesson.id

      assert [%LessonLog{operation: "UPDATE", assessment_points_ids: [^ap_id]}] =
               Repo.all(from(l in LessonLog, where: l.lesson_id == ^lesson.id))
    end

    test "link_assessment_point_to_lesson/3 is idempotent (double-link no-ops and skips the log)" do
      scope = staff_scope_fixture()
      strand = insert(:strand)
      lesson = insert(:lesson, strand: strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, moment: moment)

      {:ok, _} = Lessons.link_assessment_point_to_lesson(scope, ap.id, lesson.id)
      {:ok, _} = Lessons.link_assessment_point_to_lesson(scope, ap.id, lesson.id)

      assert [{_, _}] = linked_pairs()

      # the no-op re-link doesn't write a second (unchanged) log snapshot
      assert [%LessonLog{operation: "UPDATE"}] =
               Repo.all(from(l in LessonLog, where: l.lesson_id == ^lesson.id))
    end

    test "link_assessment_point_to_lesson/3 is additive (a second lesson does not displace the first)" do
      scope = staff_scope_fixture()
      strand = insert(:strand)
      lesson_a = insert(:lesson, strand: strand)
      lesson_b = insert(:lesson, strand: strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, moment: moment)

      {:ok, _} = Lessons.link_assessment_point_to_lesson(scope, ap.id, lesson_a.id)
      {:ok, _} = Lessons.link_assessment_point_to_lesson(scope, ap.id, lesson_b.id)

      pairs = linked_pairs()
      assert {ap.id, lesson_a.id} in pairs
      assert {ap.id, lesson_b.id} in pairs
    end

    test "link_assessment_point_to_lesson/3 succeeds on a locked strand (lock-free)" do
      scope = staff_scope_fixture()
      strand = insert(:strand, is_locked: true)
      lesson = insert(:lesson, strand: strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, moment: moment)

      assert {:ok, %Lesson{}} =
               Lessons.link_assessment_point_to_lesson(scope, ap.id, lesson.id)

      assert [{_, _}] = linked_pairs()
    end

    test "unlink_assessment_point_from_lesson/3 removes only this lesson's link" do
      scope = staff_scope_fixture()
      strand = insert(:strand)
      lesson_a = insert(:lesson, strand: strand)
      lesson_b = insert(:lesson, strand: strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, moment: moment)

      {:ok, _} = Lessons.link_assessment_point_to_lesson(scope, ap.id, lesson_a.id)
      {:ok, _} = Lessons.link_assessment_point_to_lesson(scope, ap.id, lesson_b.id)

      assert {:ok, %Lesson{}} =
               Lessons.unlink_assessment_point_from_lesson(scope, ap.id, lesson_a.id)

      assert linked_pairs() == [{ap.id, lesson_b.id}]
    end

    test "unlink_assessment_point_from_lesson/3 succeeds on a locked strand (lock-free)" do
      scope = staff_scope_fixture()
      strand = insert(:strand, is_locked: true)
      lesson = insert(:lesson, strand: strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, moment: moment)

      {:ok, _} = Lessons.link_assessment_point_to_lesson(scope, ap.id, lesson.id)

      assert {:ok, %Lesson{}} =
               Lessons.unlink_assessment_point_from_lesson(scope, ap.id, lesson.id)

      assert linked_pairs() == []
    end

    test "unlink_assessment_point_from_lesson/3 no-ops (and skips the log) when the pair is absent" do
      scope = staff_scope_fixture()
      strand = insert(:strand)
      lesson = insert(:lesson, strand: strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, moment: moment)

      assert {:ok, %Lesson{}} =
               Lessons.unlink_assessment_point_from_lesson(scope, ap.id, lesson.id)

      assert linked_pairs() == []
      assert [] = Repo.all(from(l in LessonLog, where: l.lesson_id == ^lesson.id))
    end

    test "link_assessment_point_to_lesson/3 raises when scope is not staff" do
      scope = %Lanttern.Identity.Scope{profile_type: "student"}
      strand = insert(:strand)
      lesson = insert(:lesson, strand: strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, moment: moment)

      assert_raise MatchError, fn ->
        Lessons.link_assessment_point_to_lesson(scope, ap.id, lesson.id)
      end
    end

    test "link_assessment_point_to_lesson/3 raises for a strand-owned AP (strand goal)" do
      scope = staff_scope_fixture()
      strand = insert(:strand)
      lesson = insert(:lesson, strand: strand)
      strand_goal_ap = insert(:assessment_point, strand: strand)

      assert_raise MatchError, fn ->
        Lessons.link_assessment_point_to_lesson(scope, strand_goal_ap.id, lesson.id)
      end

      assert linked_pairs() == []
    end

    test "link_assessment_point_to_lesson/3 raises for a moment AP from another strand" do
      scope = staff_scope_fixture()
      strand = insert(:strand)
      lesson = insert(:lesson, strand: strand)

      other_strand = insert(:strand)
      other_moment = insert(:moment, strand: other_strand)
      cross_strand_ap = insert(:assessment_point, moment: other_moment)

      assert_raise MatchError, fn ->
        Lessons.link_assessment_point_to_lesson(scope, cross_strand_ap.id, lesson.id)
      end

      assert linked_pairs() == []
    end
  end
end
