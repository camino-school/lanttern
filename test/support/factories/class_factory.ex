defmodule Lanttern.ClassFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def class_factory do
        %Lanttern.Schools.Class{
          name: "Class name",
          school: build(:school),
          cycle: build(:cycle)
        }
      end
    end
  end
end
