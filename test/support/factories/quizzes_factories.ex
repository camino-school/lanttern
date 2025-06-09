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
    end
  end
end
