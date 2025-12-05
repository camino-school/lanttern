defmodule Lanttern.LessonsTest do
  use Lanttern.DataCase

  import Lanttern.Factory

  alias Lanttern.Repo

  alias Lanttern.Lessons

  describe "lessons" do
    alias Lanttern.Lessons.Lesson

    @invalid_attrs %{name: nil, description: nil}

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
      assert length(result.subjects) == 2
      subject_ids = Enum.map(result.subjects, & &1.id)
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
      assert length(result.subjects) == 2
      subject_ids = Enum.map(result.subjects, & &1.id)
      assert subject_a.id in subject_ids
      assert subject_b.id in subject_ids
    end

    test "get_lesson!/2 raises when lesson does not exist" do
      assert_raise Ecto.NoResultsError, fn -> Lessons.get_lesson!(0) end
    end

    test "create_lesson/1 with valid data creates a lesson" do
      strand = insert(:strand)
      valid_attrs = %{name: "some name", description: "some description", strand_id: strand.id}

      assert {:ok, %Lesson{} = lesson} = Lessons.create_lesson(valid_attrs)
      assert lesson.name == "some name"
      assert lesson.description == "some description"
      assert lesson.strand_id == strand.id
    end

    test "create_lesson/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Lessons.create_lesson(@invalid_attrs)
    end

    test "update_lesson/2 with valid data updates the lesson" do
      lesson = insert(:lesson)
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Lesson{} = lesson} = Lessons.update_lesson(lesson, update_attrs)
      assert lesson.name == "some updated name"
      assert lesson.description == "some updated description"
    end

    test "update_lesson/2 with invalid data returns error changeset" do
      lesson = insert(:lesson)
      assert {:error, %Ecto.Changeset{}} = Lessons.update_lesson(lesson, @invalid_attrs)
      expected = Lessons.get_lesson!(lesson.id)
      assert expected.name == lesson.name
      assert expected.description == lesson.description
    end

    test "update_lessons_positions/1 update lessons position based on list order" do
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

      :ok = Lessons.update_lessons_positions(sorted_lessons_ids)

      [expected_2, expected_3, expected_1, expected_4] =
        Lessons.list_lessons(strand_id: strand.id)

      assert expected_1.id == lesson_1.id
      assert expected_2.id == lesson_2.id
      assert expected_3.id == lesson_3.id
      assert expected_4.id == lesson_4.id
    end

    test "delete_lesson/1 deletes the lesson" do
      lesson = insert(:lesson)
      assert {:ok, %Lesson{}} = Lessons.delete_lesson(lesson)
      assert_raise Ecto.NoResultsError, fn -> Lessons.get_lesson!(lesson.id) end
    end

    test "change_lesson/1 returns a lesson changeset" do
      lesson = insert(:lesson)
      assert %Ecto.Changeset{} = Lessons.change_lesson(lesson)
    end

    test "create_lesson/2 auto-calculates position scoped to strand and moment" do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)

      assert {:ok, lesson1} =
               Lessons.create_lesson(%{
                 name: "Lesson 1",
                 strand_id: strand.id,
                 moment_id: moment.id
               })

      assert {:ok, lesson2} =
               Lessons.create_lesson(%{
                 name: "Lesson 2",
                 strand_id: strand.id,
                 moment_id: moment.id
               })

      assert lesson1.position == 0
      assert lesson2.position == 1
    end

    test "strand-level lessons have independent positions from moment lessons" do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)

      # Create lesson in moment
      assert {:ok, moment_lesson} =
               Lessons.create_lesson(%{
                 name: "Moment Lesson",
                 strand_id: strand.id,
                 moment_id: moment.id
               })

      # Create strand-level lesson
      assert {:ok, strand_lesson} =
               Lessons.create_lesson(%{
                 name: "Strand Lesson",
                 strand_id: strand.id,
                 moment_id: nil
               })

      # Both start at 0 (independent sequences)
      assert moment_lesson.position == 0
      assert strand_lesson.position == 0
    end

    test "lessons in different moments have independent positions" do
      strand = insert(:strand)
      moment_a = insert(:moment, strand: strand, name: "Moment A")
      moment_b = insert(:moment, strand: strand, name: "Moment B")

      # Create lesson in moment A
      assert {:ok, lesson_a1} =
               Lessons.create_lesson(%{
                 name: "Lesson A1",
                 strand_id: strand.id,
                 moment_id: moment_a.id
               })

      # Create lesson in moment B
      assert {:ok, lesson_b1} =
               Lessons.create_lesson(%{
                 name: "Lesson B1",
                 strand_id: strand.id,
                 moment_id: moment_b.id
               })

      # Both should have position 0 (independent sequences)
      assert lesson_a1.position == 0
      assert lesson_b1.position == 0

      # Create another lesson in moment A
      assert {:ok, lesson_a2} =
               Lessons.create_lesson(%{
                 name: "Lesson A2",
                 strand_id: strand.id,
                 moment_id: moment_a.id
               })

      # Should have position 1 in moment A's sequence
      assert lesson_a2.position == 1
    end

    test "create_lesson/2 respects explicitly provided position" do
      strand = insert(:strand)

      assert {:ok, lesson} =
               Lessons.create_lesson(%{
                 name: "Lesson",
                 strand_id: strand.id,
                 position: 99
               })

      assert lesson.position == 99
    end

    test "create_lesson/1 with subjects_ids creates lesson with subjects" do
      strand = insert(:strand)
      subject_a = insert(:subject)
      subject_b = insert(:subject)

      assert {:ok, %Lesson{} = lesson} =
               Lessons.create_lesson(%{
                 name: "Lesson with subjects",
                 strand_id: strand.id,
                 subjects_ids: [subject_a.id, subject_b.id]
               })

      lesson = Repo.preload(lesson, :subjects)
      assert length(lesson.subjects) == 2
      subject_ids = Enum.map(lesson.subjects, & &1.id)
      assert subject_a.id in subject_ids
      assert subject_b.id in subject_ids
    end

    test "update_lesson/2 with subjects_ids updates lesson subjects" do
      lesson = insert(:lesson) |> Repo.preload(:subjects)
      subject_a = insert(:subject)
      subject_b = insert(:subject)
      subject_c = insert(:subject)

      # Add initial subjects
      assert {:ok, lesson} =
               Lessons.update_lesson(lesson, %{subjects_ids: [subject_a.id, subject_b.id]})

      lesson = Repo.preload(lesson, :subjects, force: true)
      assert length(lesson.subjects) == 2

      # Update subjects (replace with different set)
      assert {:ok, lesson} =
               Lessons.update_lesson(lesson, %{subjects_ids: [subject_b.id, subject_c.id]})

      lesson = Repo.preload(lesson, :subjects, force: true)
      assert length(lesson.subjects) == 2
      subject_ids = Enum.map(lesson.subjects, & &1.id)
      assert subject_b.id in subject_ids
      assert subject_c.id in subject_ids
      refute subject_a.id in subject_ids
    end

    test "update_lesson/2 with empty subjects_ids removes all subjects" do
      lesson = insert(:lesson) |> Repo.preload(:subjects)
      subject_a = insert(:subject)
      subject_b = insert(:subject)

      # Add subjects
      assert {:ok, lesson} =
               Lessons.update_lesson(lesson, %{subjects_ids: [subject_a.id, subject_b.id]})

      lesson = Repo.preload(lesson, :subjects, force: true)
      assert length(lesson.subjects) == 2

      # Remove all subjects
      assert {:ok, lesson} = Lessons.update_lesson(lesson, %{subjects_ids: []})

      lesson = Repo.preload(lesson, :subjects, force: true)
      assert lesson.subjects == []
    end
  end
end
