defmodule Lanttern.MessageAttachmentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def message_attachment_factory(attrs) do
        attachment = Map.get(attrs, :attachment, build(:attachment))
        message = Map.get(attrs, :message, build(:message))

        message_attachment =
          %Lanttern.MessageBoard.MessageAttachment{
            attachment: attachment,
            message: message,
            position: 1
          }

        message_attachment
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
