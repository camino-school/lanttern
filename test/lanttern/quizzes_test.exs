defmodule Lanttern.QuizzesTest do
  use Lanttern.DataCase

  alias Lanttern.Quizzes

  describe "quizzes" do
    alias Lanttern.Quizzes.Quiz

    @invalid_attrs %{position: nil, description: nil, title: nil}

    test "list_quizzes/0 returns all quizzes" do
      quiz = insert(:quiz) |> Ecto.reset_fields([:moment])
      assert Quizzes.list_quizzes() == [quiz]
    end

    test "get_quiz!/1 returns the quiz with given id" do
      quiz = insert(:quiz) |> Ecto.reset_fields([:moment])
      assert Quizzes.get_quiz!(quiz.id) == quiz
    end

    test "create_quiz/1 with valid data creates a quiz" do
      moment = insert(:moment)

      valid_attrs = %{
        position: 42,
        description: "some description",
        title: "some title",
        moment_id: moment.id
      }

      assert {:ok, %Quiz{} = quiz} = Quizzes.create_quiz(valid_attrs)
      assert quiz.position == 42
      assert quiz.description == "some description"
      assert quiz.title == "some title"
      assert quiz.moment_id == moment.id
    end

    test "create_quiz/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Quizzes.create_quiz(@invalid_attrs)
    end

    test "update_quiz/2 with valid data updates the quiz" do
      quiz = insert(:quiz)

      update_attrs = %{
        position: 43,
        description: "some updated description",
        title: "some updated title"
      }

      assert {:ok, %Quiz{} = quiz} = Quizzes.update_quiz(quiz, update_attrs)
      assert quiz.position == 43
      assert quiz.description == "some updated description"
      assert quiz.title == "some updated title"
    end

    test "update_quiz/2 with invalid data returns error changeset" do
      quiz = insert(:quiz) |> Ecto.reset_fields([:moment])
      assert {:error, %Ecto.Changeset{}} = Quizzes.update_quiz(quiz, @invalid_attrs)
      assert quiz == Quizzes.get_quiz!(quiz.id)
    end

    test "delete_quiz/1 deletes the quiz" do
      quiz = insert(:quiz)
      assert {:ok, %Quiz{}} = Quizzes.delete_quiz(quiz)
      assert_raise Ecto.NoResultsError, fn -> Quizzes.get_quiz!(quiz.id) end
    end

    test "change_quiz/1 returns a quiz changeset" do
      quiz = insert(:quiz)
      assert %Ecto.Changeset{} = Quizzes.change_quiz(quiz)
    end
  end
end
