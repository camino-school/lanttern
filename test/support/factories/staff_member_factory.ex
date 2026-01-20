defmodule Lanttern.StaffMemberFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def staff_member_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))

        %Lanttern.Schools.StaffMember{
          name: "Jane Doe",
          school: school,
          role: "Teacher"
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
