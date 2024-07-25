defmodule Lanttern.Filters do
  @moduledoc """
  The Filters context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Personalization
  alias Lanttern.Personalization.ProfileSettings
  alias Lanttern.Filters.ProfileStrandFilter
  alias Lanttern.Filters.ProfileReportCardFilter
  alias Lanttern.Identity.User

  @doc """
  Set current profile filters.

  If there's no profile setting, this function creates one.

  ## Examples

      iex> set_profile_current_filters(user, %{classes_ids: [1], subjects_ids: [2]})
      {:ok, %ProfileSettings{}}

      iex> set_profile_current_filters(user, %{classes_ids: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec set_profile_current_filters(User.t(), attrs :: map()) ::
          {:ok, ProfileSettings.t()} | {:error, Ecto.Changeset.t()}
  def set_profile_current_filters(%{current_profile: %{id: profile_id}}, attrs \\ %{}),
    do:
      insert_settings_or_update_filters(
        Personalization.get_profile_settings(profile_id),
        profile_id,
        attrs
      )

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
    case Personalization.get_profile_settings(profile_id) do
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
          Enum.reduce(filters, {:noop, params, %{}}, &reduce_filter(&1, &2, current_filters))

        if attrs != %{} do
          insert_settings_or_update_filters(profile_settings, profile_id, attrs)
        end

        {op, params}
    end
  end

  defp reduce_filter(atom_filter, {op, params, attrs}, current_filters) do
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
  end

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
          {:ok, any()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
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

  @doc """
  Returns the list of profile_report_card_filter.

  ## Examples

      iex> list_profile_report_card_filter()
      [%ProfileReportCardFilter{}, ...]

  """
  def list_profile_report_card_filter do
    Repo.all(ProfileReportCardFilter)
  end

  @doc """
  Returns the list of current filters related to the the given report card and profile.

  Supported filters: `classes_ids`, `linked_students_classes_ids`.

  ## Examples

      iex> list_profile_report_card_filters(1, 1)
      %{classes_ids: [1, 2, ...], linked_students_classes_ids: []}

  """
  @spec list_profile_report_card_filters(
          profile_id :: pos_integer(),
          report_card_id :: pos_integer()
        ) :: %{
          classes_ids: [pos_integer()],
          linked_students_classes_ids: [pos_integer()]
        }
  def list_profile_report_card_filters(profile_id, report_card_id) do
    filters =
      from(
        prcf in ProfileReportCardFilter,
        where: prcf.profile_id == ^profile_id,
        where: prcf.report_card_id == ^report_card_id,
        select: {prcf.class_id, prcf.linked_students_class_id}
      )
      |> Repo.all()

    classes_ids =
      filters
      |> Enum.map(fn {class_id, _} -> class_id end)
      |> Enum.filter(&Function.identity/1)

    linked_students_classes_ids =
      filters
      |> Enum.map(fn {_, class_id} -> class_id end)
      |> Enum.filter(&Function.identity/1)

    %{
      classes_ids: classes_ids,
      linked_students_classes_ids: linked_students_classes_ids
    }
  end

  @doc """
  Gets a single profile_report_card_filter.

  Raises `Ecto.NoResultsError` if the Profile report card filters does not exist.

  ## Examples

      iex> get_profile_report_card_filter!(123)
      %ProfileReportCardFilter{}

      iex> get_profile_report_card_filter!(456)
      ** (Ecto.NoResultsError)

  """
  def get_profile_report_card_filter!(id), do: Repo.get!(ProfileReportCardFilter, id)

  @doc """
  Set profile report card filters.

  ## Examples

      iex> set_profile_report_card_filters(user, 1, %{classes_ids: [1]})
      :ok

      iex> set_profile_report_card_filters(user, 1, %{classes_ids: bad_value})
      {:error, message}

  """
  @spec set_profile_report_card_filters(User.t(), pos_integer(), map()) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}

  def set_profile_report_card_filters(
        %{current_profile: %{id: profile_id}},
        report_card_id,
        filters
      ) do
    # delete existing entries for given profile/report_card
    filters
    |> Map.keys()
    |> Enum.each(&delete_profile_report_card_filters(&1, profile_id, report_card_id))

    # and insert the new values
    base_profile_report_card_filter =
      %ProfileReportCardFilter{
        profile_id: profile_id,
        report_card_id: report_card_id
      }

    types_and_ids =
      filters
      |> Enum.flat_map(fn {type, ids} ->
        Enum.map(ids, &{type, &1})
      end)

    Ecto.Multi.new()
    |> multi_insert_profile_report_card_filter(
      base_profile_report_card_filter,
      types_and_ids
    )
    |> Repo.transaction()
  end

  defp delete_profile_report_card_filters(:classes_ids, profile_id, report_card_id) do
    from(
      prcf in ProfileReportCardFilter,
      where: prcf.profile_id == ^profile_id,
      where: prcf.report_card_id == ^report_card_id,
      where: not is_nil(prcf.class_id)
    )
    |> Repo.delete_all()
  end

  defp delete_profile_report_card_filters(
         :linked_students_classes_ids,
         profile_id,
         report_card_id
       ) do
    from(
      prcf in ProfileReportCardFilter,
      where: prcf.profile_id == ^profile_id,
      where: prcf.report_card_id == ^report_card_id,
      where: not is_nil(prcf.linked_students_class_id)
    )
    |> Repo.delete_all()
  end

  defp multi_insert_profile_report_card_filter(multi, _base_profile_report_card_filter, []),
    do: multi

  defp multi_insert_profile_report_card_filter(multi, base_profile_report_card_filter, [
         {type, id} | types_and_ids
       ]) do
    %{
      profile_id: profile_id,
      report_card_id: report_card_id
    } = base_profile_report_card_filter

    # filter type to field type
    type =
      case type do
        :classes_ids -> :class_id
        :linked_students_classes_ids -> :linked_students_class_id
      end

    name = "#{profile_id}_#{report_card_id}_#{type}_#{id}"

    changeset =
      change_profile_report_card_filter(
        base_profile_report_card_filter,
        %{type => id}
      )

    multi
    |> Ecto.Multi.insert(name, changeset)
    |> multi_insert_profile_report_card_filter(
      base_profile_report_card_filter,
      types_and_ids
    )
  end

  @doc """
  Creates a profile_report_card_filter.

  ## Examples

      iex> create_profile_report_card_filter(%{field: value})
      {:ok, %ProfileReportCardFilter{}}

      iex> create_profile_report_card_filter(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_profile_report_card_filter(attrs \\ %{}) do
    %ProfileReportCardFilter{}
    |> ProfileReportCardFilter.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a profile_report_card_filter.

  ## Examples

      iex> update_profile_report_card_filter(profile_report_card_filter, %{field: new_value})
      {:ok, %ProfileReportCardFilter{}}

      iex> update_profile_report_card_filter(profile_report_card_filter, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_profile_report_card_filter(
        %ProfileReportCardFilter{} = profile_report_card_filter,
        attrs
      ) do
    profile_report_card_filter
    |> ProfileReportCardFilter.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a profile_report_card_filter.

  ## Examples

      iex> delete_profile_report_card_filter(profile_report_card_filter)
      {:ok, %ProfileReportCardFilter{}}

      iex> delete_profile_report_card_filter(profile_report_card_filter)
      {:error, %Ecto.Changeset{}}

  """
  def delete_profile_report_card_filter(%ProfileReportCardFilter{} = profile_report_card_filter) do
    Repo.delete(profile_report_card_filter)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking profile_report_card_filter changes.

  ## Examples

      iex> change_profile_report_card_filter(profile_report_card_filter)
      %Ecto.Changeset{data: %ProfileReportCardFilter{}}

  """
  def change_profile_report_card_filter(
        %ProfileReportCardFilter{} = profile_report_card_filter,
        attrs \\ %{}
      ) do
    ProfileReportCardFilter.changeset(profile_report_card_filter, attrs)
  end
end
