defmodule Lanttern.ILPCommentAttachmentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def ilp_comment_attachment_factory do
        %Lanttern.ILP.ILPCommentAttachment{
          name: "ILP Comment Attachment",
          ilp_comment: build(:ilp_comment),
          position: 1,
          link: "https://example.com",
          is_external: true
        }
      end
    end
  end
end
