defmodule Lanttern.LessonsTest do
  use Lanttern.DataCase

  import Lanttern.Factory

  alias Lanttern.Lessons

  describe "lessons" do
    alias Lanttern.Lessons.Lesson

    @invalid_attrs %{name: nil, description: nil}

    test "list_lessons/0 returns all lessons" do
      lesson = insert(:lesson)
      [expected] = Lessons.list_lessons()
      assert expected.id == lesson.id
    end

    test "get_lesson!/1 returns the lesson with given id" do
      lesson = insert(:lesson)
      expected = Lessons.get_lesson!(lesson.id)
      assert expected.id == lesson.id
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

    test "delete_lesson/1 deletes the lesson" do
      lesson = insert(:lesson)
      assert {:ok, %Lesson{}} = Lessons.delete_lesson(lesson)
      assert_raise Ecto.NoResultsError, fn -> Lessons.get_lesson!(lesson.id) end
    end

    test "change_lesson/1 returns a lesson changeset" do
      lesson = insert(:lesson)
      assert %Ecto.Changeset{} = Lessons.change_lesson(lesson)
    end
  end
end
