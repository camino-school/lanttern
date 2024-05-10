defmodule Lanttern.Notes do
  @moduledoc """
  The Notes context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.Notes.MomentNoteRelationship
  alias Lanttern.Notes.Note
  alias Lanttern.Notes.StrandNoteRelationship
  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Identity.User
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.Strand

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
  Returns the list of user notes.

  ### Options (required):

  `:strand_id` – list all moments notes for given strand. with preloaded moment and ordered by its position

  ## Examples

      iex> list_user_notes(user, opts)
      [%Note{}, ...]

  """
  def list_user_notes(%{current_profile: profile} = _user, strand_id: strand_id) do
    from(
      n in Note,
      join: mn in MomentNoteRelationship,
      on: mn.note_id == n.id,
      join: m in Moment,
      on: m.id == mn.moment_id,
      where: n.author_id == ^profile.id,
      where: m.strand_id == ^strand_id,
      order_by: m.position,
      select: %{n | moment: m}
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of student strand notes based on their report cards.

  The function lists all strands linked to the student report cards, ordering the results
  by (report card) cycle descending and strand reports position ascending.

  The list is comprised of tuples of note (or `nil`) and strand.

  ### Options:

  `:cycles_ids` – filter results by given cycles

  ## Examples

      iex> list_student_strands_notes(user, opts)
      [{%Note{}, %Strand{}}, ...]

  """
  @spec list_student_strands_notes(user :: User.t(), opts :: Keyword.t()) :: [
          {Note.t() | nil, Strand.t()}
        ]
  def list_student_strands_notes(%{current_profile: profile} = _user, opts \\ []) do
    notes_strands =
      from(
        rc in ReportCard,
        join: c in assoc(rc, :school_cycle),
        join: src in assoc(rc, :students_report_cards),
        join: sr in assoc(rc, :strand_reports),
        join: s in assoc(sr, :strand),
        left_join: n in assoc(s, :notes),
        where: src.student_id == ^profile.student_id,
        where: is_nil(n) or n.author_id == ^profile.id,
        order_by: [desc: c.end_at, asc: c.start_at, asc: sr.position],
        select: {n, s}
      )
      |> apply_list_student_strands_notes_opts(opts)
      |> Repo.all()
      |> Enum.uniq()

    # preload strand subjects and years
    updated_strands =
      notes_strands
      |> Enum.map(fn {_, strand} -> strand end)
      |> maybe_preload(preloads: [:subjects, :years])

    # put back strands with preloaded subjects and years
    notes_strands
    |> Enum.zip_with(
      updated_strands,
      fn {n, _}, s -> {n, s} end
    )
  end

  defp apply_list_student_strands_notes_opts(queryable, []), do: queryable

  defp apply_list_student_strands_notes_opts(queryable, [{:cycles_ids, cycles_ids} | opts])
       when cycles_ids != [] do
    from(
      rc in queryable,
      where: rc.school_cycle_id in ^cycles_ids
    )
    |> apply_list_student_strands_notes_opts(opts)
  end

  defp apply_list_student_strands_notes_opts(queryable, [_opt | opts]),
    do: apply_list_student_strands_notes_opts(queryable, opts)

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

  `:moment_id` – get user moment note with preloaded moment

  ## Examples

      iex> get_user_note(user, opts)
      %Note{}

      iex> get_user_note(user, opts)
      nil

  """
  def get_user_note(%{current_profile: profile} = _user, strand_id: strand_id) do
    from(
      n in Note,
      join: s in assoc(n, :strand),
      where: n.author_id == ^profile.id,
      where: s.id == ^strand_id,
      select: %{n | strand: s}
    )
    |> Repo.one()
  end

  def get_user_note(%{current_profile: profile} = _user, moment_id: moment_id) do
    from(
      n in Note,
      join: m in assoc(n, :moment),
      where: n.author_id == ^profile.id,
      where: m.id == ^moment_id,
      select: %{n | moment: m}
    )
    |> Repo.one()
  end

  @doc """
  Gets a single student note.

  Returns `nil` if the Note does not exist.

  ### Options (required):

  `:strand_id` – get student strand note with preloaded strand

  ## Examples

      iex> get_student_note(user, opts)
      %Note{}

      iex> get_student_note(user, opts)
      nil

  """
  @spec get_student_note(student_id :: pos_integer(), Keyword.t()) :: Note.t() | nil
  def get_student_note(student_id, strand_id: strand_id) do
    query =
      from(
        n in Note,
        # author is a profile
        join: p in assoc(n, :author),
        join: sn in StrandNoteRelationship,
        on: sn.note_id == n.id,
        join: s in Strand,
        on: s.id == sn.strand_id,
        where: p.student_id == ^student_id,
        where: s.id == ^strand_id,
        select: %{n | strand: s}
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
      |> Note.changeset(Map.put(attrs, "author_id", profile && profile.id))

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
  Creates a user moment note.

  ## Examples

      iex> create_moment_note(user, 1, %{field: value})
      {:ok, %Note{}}

      iex> create_moment_note(user, 1, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_moment_note(%{current_profile: profile} = _user, moment_id, attrs \\ %{}) do
    insert_query =
      %Note{}
      |> Note.changeset(Map.put(attrs, "author_id", profile && profile.id))

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert_note, insert_query)
    |> Ecto.Multi.run(
      :link_moment,
      fn _repo, %{insert_note: note} ->
        %MomentNoteRelationship{}
        |> MomentNoteRelationship.changeset(%{
          note_id: note.id,
          author_id: note.author_id,
          moment_id: moment_id
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
