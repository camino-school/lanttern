defmodule Lanttern.NotesLogTest do
  use Lanttern.DataCase

  alias Lanttern.NotesLog

  describe "notes" do
    alias Lanttern.NotesLog.NoteLog

    import Lanttern.NotesLogFixtures

    @invalid_attrs %{type: nil, description: nil, author_id: nil, operation: nil, type_id: nil}

    test "list_notes/0 returns all notes" do
      note_log = note_log_fixture()
      assert NotesLog.list_notes() == [note_log]
    end

    test "get_note_log!/1 returns the note_log with given id" do
      note_log = note_log_fixture()
      assert NotesLog.get_note_log!(note_log.id) == note_log
    end

    test "create_note_log/1 with valid data creates a note_log" do
      valid_attrs = %{
        note_id: 42,
        author_id: 42,
        description: "some description",
        operation: "UPDATE",
        type: "some type",
        type_id: 42
      }

      assert {:ok, %NoteLog{} = note_log} = NotesLog.create_note_log(valid_attrs)
      assert note_log.note_id == 42
      assert note_log.author_id == 42
      assert note_log.description == "some description"
      assert note_log.operation == "UPDATE"
      assert note_log.type == "some type"
      assert note_log.type_id == 42
    end

    test "create_note_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = NotesLog.create_note_log(@invalid_attrs)
    end
  end
end
