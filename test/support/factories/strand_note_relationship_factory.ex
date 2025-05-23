defmodule Lanttern.StrandNoteRelationshipFactory do
  @moduledoc """
  Factory for `Lanttern.Notes.StrandNoteRelationship`
  the following fields are required:
  - `note_id`
  - `author_id`
  - `strand_id`
  """
  defmacro __using__(_opts) do
    quote do
      def strand_note_relationship_factory do
        %Lanttern.Notes.StrandNoteRelationship{
          # note: build(:note),
          # author: build(:profile),
          # strand: build(:strand)
        }
      end
    end
  end
end
