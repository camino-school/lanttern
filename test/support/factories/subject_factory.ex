defmodule Lanttern.SubjectFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def subject_factory(attrs) do
        %Lanttern.Taxonomy.Subject{
          name: "Subject"
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
