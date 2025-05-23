defmodule Lanttern.NoteFactory do
  @moduledoc """
  Factory for the Note schema.
  This factory is used to create instances of the Note schema for testing purposes.
  It provides a default set of attributes for the Note schema, which can be overridden
  when creating a new instance.
  """
  defmacro __using__(_opts) do
    quote do
      def note_factory do
        %Lanttern.Notes.Note{
          # author: build(:profile),
          description: "some description"
        }
      end
    end
  end
end
