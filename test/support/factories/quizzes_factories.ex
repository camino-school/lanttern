defmodule Lanttern.QuizzesFactories do
  @moduledoc """
  This module defines factories for creating Quizzes schema structs for testing purposes.
  """
  defmacro __using__(_opts) do
    quote do
      def quiz_factory do
        %Lanttern.Quizzes.Quiz{
          position: 1,
          title: "some title",
          description: "some description",
          moment: build(:moment)
        }
      end

      def quiz_item_factory do
        %Lanttern.Quizzes.QuizItem{
          description: "some quiz item description",
          type: "text",
          quiz: build(:quiz)
        }
      end

      def quiz_item_alternative_factory do
        %Lanttern.Quizzes.QuizItemAlternative{
          description: "some quiz item alternative description",
          quiz_item: build(:quiz_item)
        }
      end

      def quiz_item_student_entry_factory do
        %Lanttern.Quizzes.QuizItemStudentEntry{
          answer: "some quiz item student entry answer",
          quiz_item: build(:quiz_item),
          student: build(:student)
        }
      end
    end
  end
end
