defmodule Lanttern.MessageBoardFactory do
  @moduledoc """
  Factory for the MessageBoard schema.
  This factory is used to create instances of the MessageBoard schema for testing purposes.
  It provides a default set of attributes for the MessageBoard schema, which can be overridden
  when creating a new instance.
  """
  defmacro __using__(_opts) do
    quote do
      def message_board_factory do
        %Lanttern.MessageBoard.Message{
          description: "some description",
          name: "some name",
          send_to: "school",
          school: build(:school)
        }
      end

      def card_section_factory do
        %Lanttern.MessageBoard.CardSection{
          name: sequence(:section_name, &"Section #{&1}")
        }
      end

      def card_message_factory do
        %Lanttern.MessageBoard.CardMessage{
          color: sequence(:message_color, ["fda4af", "86efac", "93c5fd", "d8b4fe"]),
          cover:
            sequence(:cover_url, [
              "https://images.unsplash.com/photo-1503676260728-1c00da094a0b",
              "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3"
            ]),
          title: sequence(:message_title, &"Message Title #{&1}"),
          subtitle: sequence(:message_subtitle, &"Subtitle #{&1}"),
          content:
            sequence(
              :message_content,
              &"Message content #{&1}. Lorem ipsum dolor sit amet, consectetur adipiscing elit."
            ),
          card_section: build(:card_section)
        }
      end
    end
  end
end
