defmodule Lanttern.CycleFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def cycle_factory do
        %Lanttern.Schools.Cycle{
          name: "School Cycle",
          end_at: ~U[2025-12-01 00:00:00Z],
          start_at: ~U[2025-02-01 00:00:00Z],
          school: build(:school)
        }
      end
    end
  end
end
