defmodule Lanttern.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: Lanttern.Repo

  use Lanttern.AttachmentFactory
  use Lanttern.ClassFactory
  use Lanttern.CycleFactory
  use Lanttern.ILPCommentAttachmentFactory
  use Lanttern.ILPCommentFactory
  use Lanttern.ILPTemplateFactory
  use Lanttern.MessageAttachmentFactory
  use Lanttern.MessageBoardFactory
  use Lanttern.MessageFactory
  use Lanttern.MessageClassFactory
  use Lanttern.NoteFactory
  use Lanttern.ProfileFactory
  use Lanttern.SchoolFactory
  use Lanttern.SectionFactory
  use Lanttern.StaffMemberFactory
  use Lanttern.StrandNoteRelationshipFactory
  use Lanttern.StudentFactory
  use Lanttern.StudentILPFactory
  use Lanttern.StudentRecordFactory
  use Lanttern.StudentRecordRelationshipFactory
  use Lanttern.StudentRecordStatusFactory
  use Lanttern.UserFactory
end
