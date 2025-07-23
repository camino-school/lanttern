defmodule Lanttern.ILPCommentAttachmentFactory do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def ilp_comment_attachment_factory(attrs) do
        attachment = Map.get(attrs, :attachment, build(:attachment))
        ilp_comment = Map.get(attrs, :ilp_comment, build(:ilp_comment))

        ilp_comment_attachment =
          %Lanttern.ILP.ILPCommentAttachment{
            attachment: attachment,
            ilp_comment: ilp_comment,
            position: 1
          }

        ilp_comment_attachment
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
