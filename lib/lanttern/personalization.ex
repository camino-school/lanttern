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
  alias Lanttern.Personalization.MomentNoteRelationship
  alias Lanttern.LearningContext.Moment
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

  def get_user_note(%{current_profile: profile} = _user, moment_id: moment_id) do
    query =
      from(
        n in Note,
        join: mn in MomentNoteRelationship,
        on: mn.note_id == n.id,
        join: m in Moment,
        on: m.id == mn.moment_id,
        where: n.author_id == ^profile.id,
        where: m.id == ^moment_id,
        select: %{n | moment: m}
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
  Get profile settings.

  Returns `nil` if profile has no settings.

  ## Examples

      iex> get_profile_settings(profile_id)
      %ProfileSettings{}

      iex> get_profile_settings(profile_id)
      nil

  """
  def get_profile_settings(profile_id),
    do: Repo.get_by(ProfileSettings, profile_id: profile_id)

  @doc """
  Set current profile filters.

  If there's no profile setting, this function creates one.

  ## Examples

      iex> set_profile_current_filters(user, %{classes_ids: [1], subjects_ids: [2]})
      {:ok, %ProfileSettings{}}

      iex> set_profile_current_filters(user, %{classes_ids: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def set_profile_current_filters(%{current_profile: %{id: profile_id}}, attrs \\ %{}),
    do: insert_settings_or_update_filters(get_profile_settings(profile_id), profile_id, attrs)

  defp insert_settings_or_update_filters(nil, profile_id, attrs) do
    %ProfileSettings{}
    |> ProfileSettings.changeset(%{
      profile_id: profile_id,
      current_filters: attrs
    })
    |> Repo.insert()
  end

  defp insert_settings_or_update_filters(profile_settings, _, attrs) do
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

  @doc """
  Sync params with profile filters and returns the updated params.

  This function updates the profile settings if there's some value in params for the given filters,
  or sets param values based on the profile filters — effectively allowing filter persistence between
  sessions.

  Returns a tuple with `{:noop, params}` when there's no params change, or `{:updated, params}` otherwise.

  ## Examples

      iex> sync_params_and_profile_filters(params, user, [:classes_ids])
      {:noop, %{"classes_ids" => ["1", "2", "3"]}}

      iex> sync_params_and_profile_filters(params, user, [:classes_ids])
      {:updated, %{"classes_ids" => ["4", "5", "6"]}}

  """
  def sync_params_and_profile_filters(
        params,
        %{current_profile: %{id: profile_id}} = _user,
        filters \\ []
      ) do
    case get_profile_settings(profile_id) do
      nil ->
        # update profile current filters
        attrs =
          Enum.reduce(filters, %{}, fn atom_filter, attrs ->
            str_filter = Atom.to_string(atom_filter)
            Map.put(attrs, atom_filter, params[str_filter])
          end)

        insert_settings_or_update_filters(nil, profile_id, attrs)

        # return params as is
        {:noop, params}

      profile_settings ->
        current_filters = profile_settings.current_filters || %{}

        {op, params, attrs} =
          Enum.reduce(filters, {:noop, params, %{}}, fn atom_filter, {op, params, attrs} ->
            str_filter = Atom.to_string(atom_filter)

            case {params[str_filter], Map.get(current_filters, atom_filter)} do
              {nil, nil} ->
                {op, params, attrs}

              {nil, []} ->
                {op, params, attrs}

              {nil, filter} when is_list(filter) ->
                params =
                  Map.put(
                    params,
                    str_filter,
                    Enum.map(filter, &"#{&1}")
                  )

                {:updated, params, attrs}

              {"", _filter} ->
                attrs = Map.put(attrs, atom_filter, [])
                {op, params, attrs}

              {param, _filter} ->
                attrs = Map.put(attrs, atom_filter, param)
                {op, params, attrs}
            end
          end)

        if attrs != %{} do
          insert_settings_or_update_filters(profile_settings, profile_id, attrs)
        end

        {op, params}
    end
  end

  alias Lanttern.Personalization.ProfileStrandFilter

  @doc """
  Returns the list of profile_strand_filters.

  ## Examples

      iex> list_profile_strand_filters()
      [%ProfileStrandFilter{}, ...]

  """
  def list_profile_strand_filters() do
    Repo.all(ProfileStrandFilter)
  end

  @doc """
  Returns the list of current classes ids filters for the given strand and profile.

  ## Examples

      iex> list_profile_strand_filters_classes_ids(1, 1)
      [1, 2, ...]

  """
  @spec list_profile_strand_filters_classes_ids(pos_integer(), pos_integer()) :: [pos_integer()]
  def list_profile_strand_filters_classes_ids(profile_id, strand_id) do
    from(
      psf in ProfileStrandFilter,
      where: psf.profile_id == ^profile_id,
      where: psf.strand_id == ^strand_id,
      select: psf.class_id
    )
    |> Repo.all()
  end

  @doc """
  Gets a single profile_strand_filter.

  Raises `Ecto.NoResultsError` if the Profile strand filter does not exist.

  ## Examples

      iex> get_profile_strand_filter!(123)
      %ProfileStrandFilter{}

      iex> get_profile_strand_filter!(456)
      ** (Ecto.NoResultsError)

  """
  def get_profile_strand_filter!(id), do: Repo.get!(ProfileStrandFilter, id)

  @doc """
  Set profile strand filters.

  ## Examples

      iex> set_profile_strand_filters(user, 1, %{classes_ids: [1]})
      :ok

      iex> set_profile_strand_filters(user, 1, %{classes_ids: bad_value})
      {:error, message}

  """
  @spec set_profile_strand_filters(User.t(), pos_integer(), map()) ::
          {:ok, any()} | {:error, any()} | Ecto.Multi.failure()
  def set_profile_strand_filters(%{current_profile: %{id: profile_id}}, strand_id, %{
        classes_ids: classes_ids
      })
      when is_list(classes_ids) do
    # delete existing entries for given profile/strand
    from(
      psf in ProfileStrandFilter,
      where: psf.profile_id == ^profile_id,
      where: psf.strand_id == ^strand_id
    )
    |> Repo.delete_all()

    # and insert the new values
    base_profile_strand_filter =
      %ProfileStrandFilter{
        profile_id: profile_id,
        strand_id: strand_id
      }

    Ecto.Multi.new()
    |> multi_insert_profile_strand_filter(
      base_profile_strand_filter,
      classes_ids
    )
    |> Repo.transaction()
  end

  defp multi_insert_profile_strand_filter(multi, _base_profile_strand_filter, []), do: multi

  defp multi_insert_profile_strand_filter(multi, base_profile_strand_filter, [
         class_id | classes_ids
       ]) do
    %{
      profile_id: profile_id,
      strand_id: strand_id
    } = base_profile_strand_filter

    name = "#{profile_id}_#{strand_id}_#{class_id}"

    changeset =
      change_profile_strand_filter(
        base_profile_strand_filter,
        %{class_id: class_id}
      )

    multi
    |> Ecto.Multi.insert(name, changeset)
    |> multi_insert_profile_strand_filter(
      base_profile_strand_filter,
      classes_ids
    )
  end

  @doc """
  Creates a profile_strand_filter.

  ## Examples

      iex> create_profile_strand_filter(%{field: value})
      {:ok, %ProfileStrandFilter{}}

      iex> create_profile_strand_filter(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_profile_strand_filter(attrs \\ %{}) do
    %ProfileStrandFilter{}
    |> ProfileStrandFilter.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a profile_strand_filter.

  ## Examples

      iex> update_profile_strand_filter(profile_strand_filter, %{field: new_value})
      {:ok, %ProfileStrandFilter{}}

      iex> update_profile_strand_filter(profile_strand_filter, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_profile_strand_filter(%ProfileStrandFilter{} = profile_strand_filter, attrs) do
    profile_strand_filter
    |> ProfileStrandFilter.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a profile_strand_filter.

  ## Examples

      iex> delete_profile_strand_filter(profile_strand_filter)
      {:ok, %ProfileStrandFilter{}}

      iex> delete_profile_strand_filter(profile_strand_filter)
      {:error, %Ecto.Changeset{}}

  """
  def delete_profile_strand_filter(%ProfileStrandFilter{} = profile_strand_filter) do
    Repo.delete(profile_strand_filter)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking profile_strand_filter changes.

  ## Examples

      iex> change_profile_strand_filter(profile_strand_filter)
      %Ecto.Changeset{data: %ProfileStrandFilter{}}

  """
  def change_profile_strand_filter(%ProfileStrandFilter{} = profile_strand_filter, attrs \\ %{}) do
    ProfileStrandFilter.changeset(profile_strand_filter, attrs)
  end
end
