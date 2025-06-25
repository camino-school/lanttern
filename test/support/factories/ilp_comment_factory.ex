defmodule Lanttern.ILPCommentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def ilp_comment_factory do
        %Lanttern.ILP.ILPComment{
          content: "some content",
          student_ilp: build(:student_ilp),
          owner: build(:profile)
        }
      end
    end
  end
end
