defmodule Lanttern.StudentILPFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def student_ilp_factory do
        %Lanttern.ILP.StudentILP{
          # template: build(:ilp_template),
          # student: build(:student),
          # cycle: build(:cycle),
          # school: build(:school)
        }
      end
    end
  end
end
