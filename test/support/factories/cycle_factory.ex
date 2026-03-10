defmodule Lanttern.CycleFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def cycle_factory do
        %Lanttern.Schools.Cycle{
          name: "School Cycle",
          start_at: ~D[2025-02-01],
          end_at: ~D[2025-12-01],
          school: build(:school)
        }
      end
    end
  end
end
