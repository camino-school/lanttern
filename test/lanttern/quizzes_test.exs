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

  describe "quiz_item_alternatives" do
    alias Lanttern.Quizzes.QuizItemAlternative

    @invalid_attrs %{position: nil, description: nil}

    test "list_quiz_item_alternatives/0 returns all quiz_item_alternatives" do
      quiz_item_alternative = insert(:quiz_item_alternative) |> Ecto.reset_fields([:quiz_item])
      assert Quizzes.list_quiz_item_alternatives() == [quiz_item_alternative]
    end

    test "get_quiz_item_alternative!/1 returns the quiz_item_alternative with given id" do
      quiz_item_alternative = insert(:quiz_item_alternative) |> Ecto.reset_fields([:quiz_item])
      assert Quizzes.get_quiz_item_alternative!(quiz_item_alternative.id) == quiz_item_alternative
    end

    test "create_quiz_item_alternative/1 with valid data creates a quiz_item_alternative" do
      quiz_item = insert(:quiz_item)

      valid_attrs = %{
        position: 42,
        description: "some description",
        is_correct: true,
        quiz_item_id: quiz_item.id
      }

      assert {:ok, %QuizItemAlternative{} = quiz_item_alternative} =
               Quizzes.create_quiz_item_alternative(valid_attrs)

      assert quiz_item_alternative.position == 42
      assert quiz_item_alternative.description == "some description"
      assert quiz_item_alternative.is_correct
      assert quiz_item_alternative.quiz_item_id == quiz_item.id
    end

    test "prevent more than one correct alternative per question" do
      quiz_item = insert(:quiz_item)

      valid_attrs_1 = %{description: "wrong", quiz_item_id: quiz_item.id}
      valid_attrs_2 = %{description: "wrong", quiz_item_id: quiz_item.id}
      valid_attrs_3 = %{description: "right", quiz_item_id: quiz_item.id, is_correct: true}
      valid_attrs_4 = %{description: "right", quiz_item_id: quiz_item.id, is_correct: true}

      assert {:ok, %QuizItemAlternative{}} =
               Quizzes.create_quiz_item_alternative(valid_attrs_1)

      assert {:ok, %QuizItemAlternative{}} =
               Quizzes.create_quiz_item_alternative(valid_attrs_2)

      assert {:ok, %QuizItemAlternative{}} =
               Quizzes.create_quiz_item_alternative(valid_attrs_3)

      assert {:error,
              %Ecto.Changeset{
                errors: [
                  is_correct: {"There's already a correct alternative for this question", _}
                ]
              }} =
               Quizzes.create_quiz_item_alternative(valid_attrs_4)
    end

    test "create_quiz_item_alternative/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Quizzes.create_quiz_item_alternative(@invalid_attrs)
    end

    test "update_quiz_item_alternative/2 with valid data updates the quiz_item_alternative" do
      quiz_item_alternative = insert(:quiz_item_alternative)
      update_attrs = %{position: 43, description: "some updated description", is_correct: false}

      assert {:ok, %QuizItemAlternative{} = quiz_item_alternative} =
               Quizzes.update_quiz_item_alternative(quiz_item_alternative, update_attrs)

      assert quiz_item_alternative.position == 43
      assert quiz_item_alternative.description == "some updated description"
      assert quiz_item_alternative.is_correct == false
    end

    test "update_quiz_item_alternative/2 with invalid data returns error changeset" do
      quiz_item_alternative = insert(:quiz_item_alternative) |> Ecto.reset_fields([:quiz_item])

      assert {:error, %Ecto.Changeset{}} =
               Quizzes.update_quiz_item_alternative(quiz_item_alternative, @invalid_attrs)

      assert quiz_item_alternative == Quizzes.get_quiz_item_alternative!(quiz_item_alternative.id)
    end

    test "delete_quiz_item_alternative/1 deletes the quiz_item_alternative" do
      quiz_item_alternative = insert(:quiz_item_alternative)

      assert {:ok, %QuizItemAlternative{}} =
               Quizzes.delete_quiz_item_alternative(quiz_item_alternative)

      assert_raise Ecto.NoResultsError, fn ->
        Quizzes.get_quiz_item_alternative!(quiz_item_alternative.id)
      end
    end

    test "change_quiz_item_alternative/1 returns a quiz_item_alternative changeset" do
      quiz_item_alternative = insert(:quiz_item_alternative)
      assert %Ecto.Changeset{} = Quizzes.change_quiz_item_alternative(quiz_item_alternative)
    end
  end
end
