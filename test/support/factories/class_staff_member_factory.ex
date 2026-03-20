defmodule Lanttern.ClassStaffMemberFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def class_staff_member_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))
        class = Map.get(attrs, :class, build(:class, school: school))
        staff_member = Map.get(attrs, :staff_member, build(:staff_member, school: school))

        attrs = Map.drop(attrs, [:school])

        %Lanttern.Schools.ClassStaffMember{
          class: class,
          staff_member: staff_member,
          position: 0
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
