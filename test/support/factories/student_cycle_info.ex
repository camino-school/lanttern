defmodule Lanttern.StudentCycleInfoFactory do
  @moduledoc """
  Factory for the Section schema.
  This factory is used to create instances of the StudentCycleInfo schema for testing purposes.
  It provides a default set of attributes for the StudentCycleInfo schema, which can be overridden
  when creating a new instance.
  """
  defmacro __using__(_opts) do
    quote do
      def student_cycle_info_factory do
        %Lanttern.StudentsCycleInfo.StudentCycleInfo{
          student: build(:student),
          cycle: build(:cycle),
          school: build(:school)
        }
      end
    end
  end
end
