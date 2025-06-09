defmodule Lanttern.QuizzesFactories do
  @moduledoc """
  This module defines factories for creating Quizzes schema structs for testing purposes.
  """
  defmacro __using__(_opts) do
    quote do
      @doc """
      For proper use it's mandatory to include:

          moment: %Lanttern.LearningContext.Moment{}
      """
      def quiz_factory do
        %Lanttern.Quizzes.Quiz{
          position: 1,
          title: "some title",
          description: "some description",
          moment: build(:moment)
        }
      end
    end
  end
end
