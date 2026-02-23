defmodule Lanttern.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: Lanttern.Repo

  use Lanttern.AgentFactory
  use Lanttern.AgentMessageFactory
  use Lanttern.AttachmentFactory
  use Lanttern.ClassFactory
  use Lanttern.ConversationFactory
  use Lanttern.CycleFactory
  use Lanttern.ILPCommentAttachmentFactory
  use Lanttern.ILPCommentFactory
  use Lanttern.ILPTemplateFactory
  use Lanttern.LessonAttachmentFactory
  use Lanttern.LessonFactory
  use Lanttern.LessonLogFactory
  use Lanttern.LessonTagFactory
  use Lanttern.LessonTemplateFactory
  use Lanttern.MessageBoardFactory
  use Lanttern.MessageFactory
  use Lanttern.ModelCallFactory
  use Lanttern.MomentFactory
  use Lanttern.ProfileFactory
  use Lanttern.AiConfigFactory
  use Lanttern.SchoolFactory
  use Lanttern.SectionFactory
  use Lanttern.StaffMemberFactory
  use Lanttern.StrandConversationFactory
  use Lanttern.StrandFactory
  use Lanttern.StudentFactory
  use Lanttern.StudentILPFactory
  use Lanttern.StudentRecordAttachmentFactory
  use Lanttern.StudentRecordFactory
  use Lanttern.StudentRecordRelationshipFactory
  use Lanttern.StudentRecordStatusFactory
  use Lanttern.SubjectFactory
  use Lanttern.UserFactory
end
