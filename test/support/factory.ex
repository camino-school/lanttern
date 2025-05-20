defmodule Lanttern.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: Lanttern.Repo

  use Lanttern.MessageBoardFactory
  use Lanttern.NoteFactory
  use Lanttern.SchoolFactory
  use Lanttern.StrandNoteRelationshipFactory
  use Lanttern.StudentRecordFactory
  use Lanttern.StudentRecordRelationshipFactory
  use Lanttern.StudentRecordStatusFactory
end
