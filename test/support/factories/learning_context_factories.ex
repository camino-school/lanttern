defmodule Lanttern.LearningContextFactories do
  @moduledoc """
  This module defines factories for creating LearningContext schema structs for testing purposes.
  """
  defmacro __using__(_opts) do
    quote do
      def strand_factory do
        %Lanttern.LearningContext.Strand{
          name: "some strand name",
          description: "some strand description"
        }
      end

      @doc """
      For proper use it's mandatory to include:

          strand: %Lanttern.LearningContext.Strand{}
      """
      def moment_factory do
        %Lanttern.LearningContext.Moment{
          name: "some moment name",
          description: "some moment description",
          strand: build(:strand)
        }
      end
    end
  end
end
