defmodule Lanttern.MessageFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def message_factory(attrs) do
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

      def message_class_factory(attrs) do
        school = Map.get(attrs, :school, build(:school))
        message = Map.get(attrs, :message, build(:message, school: school))
        class = Map.get(attrs, :class, build(:class, school: school))

        message_class =
          %Lanttern.MessageBoard.MessageClassV2{
            message: message,
            class: class,
            school: school
          }

        message_class
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
