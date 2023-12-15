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
  alias Lanttern.Personalization.ProfileView
  alias Lanttern.Personalization.ProfileSettings

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

  `:strand_id` – list all activities notes for given strand. with preloaded activity and ordered by its position

  ## Examples

      iex> list_user_notes(user, opts)
      [%Note{}, ...]

  """
  def list_user_notes(%{current_profile: profile} = _user, strand_id: strand_id) do
    from(
      n in Note,
      join: an in ActivityNoteRelationship,
      on: an.note_id == n.id,
      join: a in Activity,
      on: a.id == an.activity_id,
      where: n.author_id == ^profile.id,
      where: a.strand_id == ^strand_id,
      order_by: a.position,
      select: %{n | activity: a}
    )
    |> Repo.all()
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
      |> Note.changeset(Map.put(attrs, "author_id", profile && profile.id))

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

  @doc """
  Returns the list of profile_views.

  ## Options

      - `:preloads` – preloads associated data
      - `:profile_id` – filter views by provided assessment point id

  ## Examples

      iex> list_profile_views()
      [%ProfileView{}, ...]

  """
  def list_profile_views(opts \\ []) do
    ProfileView
    |> filter_list_profile_views(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp filter_list_profile_views(queryable, opts) when is_list(opts),
    do: Enum.reduce(opts, queryable, &filter_list_profile_views/2)

  defp filter_list_profile_views({:profile_id, profile_id}, queryable) do
    from v in queryable,
      join: p in assoc(v, :profile),
      where: p.id == ^profile_id
  end

  defp filter_list_profile_views(_, queryable),
    do: queryable

  @doc """
  Gets a single profile_view.

  Raises `Ecto.NoResultsError` if the profile view does not exist.

  ## Options

      - `:preloads` – preloads associated data

  ## Examples

      iex> get_profile_view!(123)
      %ProfileView{}

      iex> get_profile_view!(456)
      ** (Ecto.NoResultsError)

  """
  def get_profile_view!(id, opts \\ []) do
    Repo.get!(ProfileView, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a profile_view.

  ## Examples

      iex> create_profile_view(%{field: value})
      {:ok, %ProfileView{}}

      iex> create_profile_view(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_profile_view(attrs \\ %{}) do
    # add classes and subjects to force return with preloaded classes/subjects
    %ProfileView{classes: [], subjects: []}
    |> ProfileView.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a profile_view.

  ## Examples

      iex> update_profile_view(profile_view, %{field: new_value})
      {:ok, %ProfileView{}}

      iex> update_profile_view(profile_view, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_profile_view(
        %ProfileView{} = profile_view,
        attrs
      ) do
    profile_view
    |> ProfileView.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a profile_view.

  ## Examples

      iex> delete_profile_view(profile_view)
      {:ok, %ProfileView{}}

      iex> delete_profile_view(profile_view)
      {:error, %Ecto.Changeset{}}

  """
  def delete_profile_view(%ProfileView{} = profile_view) do
    Repo.delete(profile_view)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking profile_view changes.

  ## Examples

      iex> change_profile_view(profile_view)
      %Ecto.Changeset{data: %ProfileView{}}

  """
  def change_profile_view(
        %ProfileView{} = profile_view,
        attrs \\ %{}
      ) do
    ProfileView.changeset(profile_view, attrs)
  end

  @doc """
  Set current profile filters.

  If there's no profile setting, this function creates one.

  ## Examples

      iex> set_profile_current_filters(user, %{classes_ids: [1], subjects_ids: [2]})
      {:ok, %ProfileSettings{}}

      iex> set_profile_current_filters(user, %{classes_ids: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def set_profile_current_filters(current_user, attrs \\ %{})

  def set_profile_current_filters(%{current_profile: %{id: profile_id, settings: nil}}, attrs) do
    %ProfileSettings{}
    |> ProfileSettings.changeset(%{
      profile_id: profile_id,
      current_filters: attrs
    })
    |> Repo.insert()
  end

  def set_profile_current_filters(%{current_profile: %{settings: profile_settings}}, attrs) do
    profile_settings
    |> ProfileSettings.changeset(%{
      current_filters:
        case profile_settings.current_filters do
          nil -> attrs
          current_filters -> Map.from_struct(current_filters) |> Map.merge(attrs)
        end
    })
    |> Repo.update()
  end
end
