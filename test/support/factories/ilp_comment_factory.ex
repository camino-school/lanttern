defmodule Lanttern.ILPCommentFactory do
  @moduledoc """
  This module defines a factory for creating ILPComment structs for testing purposes.
  For proper use it's mandatory to include:

      student_ilp: %Lanttern.ILP.StudentILP{}
      owner: %Lanttern.Identity.Profile{}

  both associated with the same `%Lanttern.Schools.School{}`.
  """
  defmacro __using__(_opts) do
    quote do
      def ilp_comment_factory do
        %Lanttern.ILP.ILPComment{
          content: "some content",
          position: 1
        }
      end
    end
  end
end
