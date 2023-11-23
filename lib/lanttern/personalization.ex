defmodule Lanttern.Personalization do
  @moduledoc """
  The Personalization context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo
  import Lanttern.RepoHelpers
  alias Lanttern.Personalization.Note
  alias Lanttern.Personalization.StrandNoteRelationship
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Personalization.ActivityNoteRelationship
  alias Lanttern.LearningContext.Activity

  @doc """
  Returns the list of notes.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> list_notes()
      [%Note{}, ...]

  """
  def list_notes(opts \\ []) do
    Repo.all(Note)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single note.

  Raises `Ecto.NoResultsError` if the Note does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_note!(123)
      %Note{}

      iex> get_note!(456)
      ** (Ecto.NoResultsError)

  """
  def get_note!(id, opts \\ []) do
    Repo.get!(Note, id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single user note.

  Returns `nil` if the Note does not exist.

  ### Options (required):

  `:strand_id` – get user strand note with preloaded strand

  `:activity_id` – get user activity note with preloaded activity

  ## Examples

      iex> get_user_note(user, opts)
      %Note{}

      iex> get_user_note(user, opts)
      nil

  """
  def get_user_note(%{current_profile: profile} = _user, strand_id: strand_id) do
    query =
      from(
        n in Note,
        join: sn in StrandNoteRelationship,
        on: sn.note_id == n.id,
        join: s in Strand,
        on: s.id == sn.strand_id,
        where: n.author_id == ^profile.id,
        where: s.id == ^strand_id,
        select: %{n | strand: s}
      )

    Repo.one(query)
  end

  def get_user_note(%{current_profile: profile} = _user, activity_id: activity_id) do
    query =
      from(
        n in Note,
        join: an in ActivityNoteRelationship,
        on: an.note_id == n.id,
        join: a in Activity,
        on: a.id == an.activity_id,
        where: n.author_id == ^profile.id,
        where: a.id == ^activity_id,
        select: %{n | activity: a}
      )

    Repo.one(query)
  end

  @doc """
  Creates a note.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> create_note(%{field: value})
      {:ok, %Note{}}

      iex> create_note(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_note(attrs \\ %{}, opts \\ []) do
    %Note{}
    |> Note.changeset(attrs)
    |> Repo.insert()
    |> maybe_preload(opts)
  end

  @doc """
  Creates a user strand note.

  ## Examples

      iex> create_strand_note(user, 1, %{field: value})
      {:ok, %Note{}}

      iex> create_strand_note(user, 1, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_strand_note(%{current_profile: profile} = _user, strand_id, attrs \\ %{}) do
    insert_query =
      %Note{}
      |> Note.changeset(Map.put(attrs, :author_id, profile && profile.id))

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert_note, insert_query)
    |> Ecto.Multi.run(
      :link_strand,
      fn _repo, %{insert_note: note} ->
        %StrandNoteRelationship{}
        |> StrandNoteRelationship.changeset(%{
          note_id: note.id,
          author_id: note.author_id,
          strand_id: strand_id
        })
        |> Repo.insert()
      end
    )
    |> Repo.transaction()
    |> case do
      {:error, _multi, changeset, _changes} -> {:error, changeset}
      {:ok, %{insert_note: note}} -> {:ok, note}
    end
  end

  @doc """
  Creates a user activity note.

  ## Examples

      iex> create_activity_note(user, 1, %{field: value})
      {:ok, %Note{}}

      iex> create_activity_note(user, 1, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_activity_note(%{current_profile: profile} = _user, activity_id, attrs \\ %{}) do
    insert_query =
      %Note{}
      |> Note.changeset(Map.put(attrs, :author_id, profile && profile.id))

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert_note, insert_query)
    |> Ecto.Multi.run(
      :link_activity,
      fn _repo, %{insert_note: note} ->
        %ActivityNoteRelationship{}
        |> ActivityNoteRelationship.changeset(%{
          note_id: note.id,
          author_id: note.author_id,
          activity_id: activity_id
        })
        |> Repo.insert()
      end
    )
    |> Repo.transaction()
    |> case do
      {:error, _multi, changeset, _changes} -> {:error, changeset}
      {:ok, %{insert_note: note}} -> {:ok, note}
    end
  end

  @doc """
  Updates a note.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> update_note(note, %{field: new_value})
      {:ok, %Note{}}

      iex> update_note(note, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_note(%Note{} = note, attrs, opts \\ []) do
    note
    |> Note.changeset(attrs)
    |> Repo.update()
    |> maybe_preload(opts)
  end

  @doc """
  Deletes a note.

  ## Examples

      iex> delete_note(note)
      {:ok, %Note{}}

      iex> delete_note(note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_note(%Note{} = note) do
    Repo.delete(note)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking note changes.

  ## Examples

      iex> change_note(note)
      %Ecto.Changeset{data: %Note{}}

  """
  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end
end
