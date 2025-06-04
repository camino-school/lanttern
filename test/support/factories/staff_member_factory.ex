defmodule Lanttern.StaffMemberFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def staff_member_factory do
        %Lanttern.Schools.StaffMember{
          name: "Jane Doe",
          school: build(:school),
          role: "Teacher"
        }
      end
    end
  end
end
