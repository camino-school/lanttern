defmodule Lanttern.SubjectFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def subject_factory do
        %Lanttern.Taxonomy.Subject{name: "Subject"}
      end
    end
  end
end
