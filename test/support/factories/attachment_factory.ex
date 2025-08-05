defmodule Lanttern.AttachmentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def attachment_factory(attrs) do
        owner = Map.get(attrs, :owner, build(:profile))

        attachment =
          %Lanttern.Attachments.Attachment{
            name: "Attachment",
            link: "https://example.com",
            is_external: true,
            owner: owner
          }

        attachment
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
