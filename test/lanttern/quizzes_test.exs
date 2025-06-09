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

  describe "quiz_items" do
    alias Lanttern.Quizzes.QuizItem

    @invalid_attrs %{position: nil, type: nil, description: nil}

    test "list_quiz_items/0 returns all quiz_items" do
      quiz_item = insert(:quiz_item) |> Ecto.reset_fields([:quiz])
      assert Quizzes.list_quiz_items() == [quiz_item]
    end

    test "get_quiz_item!/1 returns the quiz_item with given id" do
      quiz_item = insert(:quiz_item) |> Ecto.reset_fields([:quiz])
      assert Quizzes.get_quiz_item!(quiz_item.id) == quiz_item
    end

    test "create_quiz_item/1 with valid data creates a quiz_item" do
      quiz = insert(:quiz)

      valid_attrs = %{
        position: 42,
        type: "multiple_choice",
        description: "some description abc",
        quiz_id: quiz.id
      }

      assert {:ok, %QuizItem{} = quiz_item} = Quizzes.create_quiz_item(valid_attrs)
      assert quiz_item.position == 42
      assert quiz_item.type == "multiple_choice"
      assert quiz_item.description == "some description abc"
      assert quiz_item.quiz_id == quiz.id
    end

    test "create_quiz_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Quizzes.create_quiz_item(@invalid_attrs)
    end

    test "update_quiz_item/2 with valid data updates the quiz_item" do
      quiz_item = insert(:quiz_item)

      update_attrs = %{
        position: 43,
        type: "multiple_choice",
        description: "some updated description"
      }

      assert {:ok, %QuizItem{} = quiz_item} = Quizzes.update_quiz_item(quiz_item, update_attrs)
      assert quiz_item.position == 43
      assert quiz_item.type == "multiple_choice"
      assert quiz_item.description == "some updated description"
    end

    test "update_quiz_item/2 with invalid data returns error changeset" do
      quiz_item = insert(:quiz_item) |> Ecto.reset_fields([:quiz])
      assert {:error, %Ecto.Changeset{}} = Quizzes.update_quiz_item(quiz_item, @invalid_attrs)
      assert quiz_item == Quizzes.get_quiz_item!(quiz_item.id)
    end

    test "delete_quiz_item/1 deletes the quiz_item" do
      quiz_item = insert(:quiz_item)
      assert {:ok, %QuizItem{}} = Quizzes.delete_quiz_item(quiz_item)
      assert_raise Ecto.NoResultsError, fn -> Quizzes.get_quiz_item!(quiz_item.id) end
    end

    test "change_quiz_item/1 returns a quiz_item changeset" do
      quiz_item = insert(:quiz_item)
      assert %Ecto.Changeset{} = Quizzes.change_quiz_item(quiz_item)
    end
  end
end
