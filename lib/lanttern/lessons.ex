defmodule Lanttern.Lessons do
  @moduledoc """
  The Lessons context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers, only: [maybe_preload: 2, update_positions: 2, update_positions: 3]
  alias Lanttern.Repo

  alias Lanttern.Attachments.Attachment
  alias Lanttern.Lessons.Lesson
  alias Lanttern.Lessons.LessonAttachment

  @doc """
  Returns the list of lessons.

  ## Options

  - `:strand_id` – filter lessons by strand
  - `:subjects_ids` – filter lessons by subjects
  - `:preloads` – preloads associated data

  ## Examples

      iex> list_lessons()
      [%Lesson{}, ...]

  """
  def list_lessons(opts \\ []) do
    from(
      l in Lesson,
      order_by: l.position,
      distinct: true
    )
    |> apply_list_lessons_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_lessons_opts(queryable, []), do: queryable

  defp apply_list_lessons_opts(queryable, [{:strand_id, strand_id} | opts]) do
    from(
      l in queryable,
      where: l.strand_id == ^strand_id
    )
    |> apply_list_lessons_opts(opts)
  end

  defp apply_list_lessons_opts(queryable, [{:subjects_ids, subjects_ids} | opts])
       when is_list(subjects_ids) and subjects_ids != [] do
    from(
      l in queryable,
      join: ls in "lessons_subjects",
      on: ls.lesson_id == l.id,
      where: ls.subject_id in ^subjects_ids
    )
    |> apply_list_lessons_opts(opts)
  end

  defp apply_list_lessons_opts(queryable, [_ | opts]),
    do: apply_list_lessons_opts(queryable, opts)

  @doc """
  Gets a single lesson.

  Returns `nil` if the Lesson does not exist.

  ## Options

  - `:preloads` – preloads associated data

  ## Examples

      iex> get_lesson(123)
      %Lesson{}

      iex> get_lesson(456)
      nil

  """
  def get_lesson(id, opts \\ []) do
    Lesson
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single lesson.

  Same as `get_lesson/2`, but raises `Ecto.NoResultsError` if the Lesson does not exist.

  ## Options

  - `:preloads` – preloads associated data

  ## Examples

      iex> get_lesson!(123)
      %Lesson{}

      iex> get_lesson!(456)
      ** (Ecto.NoResultsError)

  """
  def get_lesson!(id, opts \\ []) do
    Lesson
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a lesson.

  ## Options

  - `:preloads` – preloads associated data

  ## Examples

      iex> create_lesson(%{field: value})
      {:ok, %Lesson{}}

      iex> create_lesson(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_lesson(attrs, opts \\ []) do
    %Lesson{}
    |> Lesson.changeset(attrs)
    |> set_lesson_position()
    |> Repo.insert()
    |> maybe_preload(opts)
  end

  # skip if not valid
  defp set_lesson_position(%Ecto.Changeset{valid?: false} = changeset),
    do: changeset

  # skip if changeset already has position change
  defp set_lesson_position(%Ecto.Changeset{changes: %{position: _position}} = changeset),
    do: changeset

  defp set_lesson_position(%Ecto.Changeset{} = changeset) do
    strand_id = Ecto.Changeset.get_field(changeset, :strand_id)
    moment_id = Ecto.Changeset.get_field(changeset, :moment_id)

    position =
      from(l in Lesson,
        where: l.strand_id == ^strand_id,
        select: l.position,
        order_by: [desc: l.position],
        limit: 1
      )
      |> where_moment_id(moment_id)
      |> Repo.one()
      |> case do
        nil -> 0
        pos -> pos + 1
      end

    Ecto.Changeset.put_change(changeset, :position, position)
  end

  defp where_moment_id(query, nil), do: where(query, [l], is_nil(l.moment_id))
  defp where_moment_id(query, moment_id), do: where(query, [l], l.moment_id == ^moment_id)

  @doc """
  Updates a lesson.

  ## Examples

      iex> update_lesson(lesson, %{field: new_value})
      {:ok, %Lesson{}}

      iex> update_lesson(lesson, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_lesson(%Lesson{} = lesson, attrs) do
    lesson
    |> Lesson.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Update lessons positions based on ids list order.

  ## Examples

  iex> update_lessons_positions([3, 2, 1])
  :ok

  """
  @spec update_lessons_positions(lessons_ids :: [pos_integer()]) ::
          :ok | {:error, String.t()}
  def update_lessons_positions(lessons_ids),
    do: update_positions(Lesson, lessons_ids)

  @doc """
  Deletes a lesson.

  ## Examples

      iex> delete_lesson(lesson)
      {:ok, %Lesson{}}

      iex> delete_lesson(lesson)
      {:error, %Ecto.Changeset{}}

  """
  def delete_lesson(%Lesson{} = lesson) do
    Repo.delete(lesson)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking lesson changes.

  ## Examples

      iex> change_lesson(lesson)
      %Ecto.Changeset{data: %Lesson{}}

  """
  def change_lesson(%Lesson{} = lesson, attrs \\ %{}) do
    Lesson.changeset(lesson, attrs)
  end

  # Lesson attachments

  @doc """
  Creates a lesson attachment.

  Returns `{:ok, attachment}` on success.

  The attachment is returned with a virtual `:is_teacher_only` field.

  ## Examples

      iex> create_lesson_attachment(profile_id, lesson_id, %{name: "doc", link: "http://..."}, false)
      {:ok, %Attachment{is_teacher_only: false}}

  """
  @spec create_lesson_attachment(
          profile_id :: pos_integer(),
          lesson_id :: pos_integer(),
          attachment_attrs :: map(),
          is_teacher_only_resource :: boolean()
        ) ::
          {:ok, Attachment.t()} | {:error, Ecto.Changeset.t()}
  def create_lesson_attachment(
        profile_id,
        lesson_id,
        attachment_attrs,
        is_teacher_only_resource \\ true
      ) do
    insert_query =
      %Attachment{}
      |> Attachment.changeset(Map.put(attachment_attrs, "owner_id", profile_id))

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert_attachment, insert_query)
    |> Ecto.Multi.run(
      :link_lesson,
      fn _repo, %{insert_attachment: attachment} ->
        attrs =
          from(
            la in LessonAttachment,
            where: la.lesson_id == ^lesson_id
          )
          |> set_position_in_attrs(%{
            lesson_id: lesson_id,
            attachment_id: attachment.id,
            is_teacher_only_resource: is_teacher_only_resource,
            owner_id: profile_id
          })

        %LessonAttachment{}
        |> LessonAttachment.changeset(attrs)
        |> Repo.insert()
      end
    )
    |> Repo.transaction()
    |> case do
      {:error, _multi, changeset, _changes} ->
        {:error, changeset}

      {:ok, %{insert_attachment: attachment}} ->
        {:ok, %{attachment | is_teacher_only: is_teacher_only_resource}}
    end
  end

  defp set_position_in_attrs(query, attrs) do
    position =
      query
      |> select([q], q.position)
      |> order_by([q], desc: q.position)
      |> limit(1)
      |> Repo.one()
      |> case do
        nil -> 0
        pos -> pos + 1
      end

    Map.put(attrs, :position, position)
  end

  @doc """
  Update lesson attachments positions based on ids list order.

  ## Examples

      iex> update_lesson_attachments_positions([3, 2, 1])
      :ok

  """
  @spec update_lesson_attachments_positions(attachments_ids :: [pos_integer()]) ::
          :ok | {:error, String.t()}
  def update_lesson_attachments_positions(attachments_ids),
    do: update_positions(LessonAttachment, attachments_ids, id_field: :attachment_id)

  @doc """
  Toggle the lesson attachment `is_teacher_only_resource` field and returns the attachment with `is_teacher_only` field updated.

  ## Examples

      iex> toggle_lesson_attachment_share(attachment)
      {:ok, %Attachment{is_teacher_only: false}}

      iex> toggle_lesson_attachment_share(attachment)
      {:error, %Ecto.Changeset{}}

  """
  @spec toggle_lesson_attachment_share(Attachment.t()) ::
          {:ok, Attachment.t()} | {:error, Ecto.Changeset.t()}
  def toggle_lesson_attachment_share(attachment) do
    lesson_attachment =
      Repo.get_by!(
        LessonAttachment,
        attachment_id: attachment.id
      )

    lesson_attachment
    |> LessonAttachment.changeset(%{
      is_teacher_only_resource: !lesson_attachment.is_teacher_only_resource
    })
    |> Repo.update()
    |> case do
      {:ok, updated_lesson_attachment} ->
        {:ok, %{attachment | is_teacher_only: updated_lesson_attachment.is_teacher_only_resource}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
