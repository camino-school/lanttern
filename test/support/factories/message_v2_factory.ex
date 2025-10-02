defmodule Lanttern.MessageV2Factory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def message_v2_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))
        section = Map.get(attrs, :section, build(:section, school: school))

        message =
          %Lanttern.MessageBoard.MessageV2{
            name: "Message Name",
            description: "Message Description",
            send_to: :school,
            school: school,
            section: section,
            subtitle: "Subtitle",
            color: "#FF0000",
            position: 0
          }

        message
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
