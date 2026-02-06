defmodule Lanttern.Lessons do
  @moduledoc """
  The Lessons context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.Attachments.Attachment
  alias Lanttern.Identity.Scope
  alias Lanttern.Lessons.Lesson
  alias Lanttern.Lessons.LessonAttachment
  alias Lanttern.Lessons.Tag

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

  @doc """
  Subscribes to scoped notifications about any tag changes.

  The broadcasted messages match the pattern:

    * {:created, %Tag{}}
    * {:updated, %Tag{}}
    * {:deleted, %Tag{}}

  """
  def subscribe_lesson_tags(%Scope{} = scope) do
    key = scope.school_id

    Phoenix.PubSub.subscribe(Lanttern.PubSub, "school:#{key}:lesson_tags")
  end

  defp broadcast_tag(%Scope{} = scope, message) do
    key = scope.school_id

    Phoenix.PubSub.broadcast(Lanttern.PubSub, "school:#{key}:lesson_tags", message)
  end

  @doc """
  Returns the list of lesson_tags.

  ## Examples

      iex> list_lesson_tags(scope)
      [%Tag{}, ...]

  """
  def list_lesson_tags(%Scope{} = scope) do
    from(t in Tag,
      where: t.school_id == ^scope.school_id,
      order_by: [asc: t.position]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(scope, 123)
      %Tag{}

      iex> get_tag!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_tag!(%Scope{} = scope, id) do
    Repo.get_by!(Tag, id: id, school_id: scope.school_id)
  end

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(scope, %{field: value})
      {:ok, %Tag{}}

      iex> create_tag(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(%Scope{} = scope, attrs) do
    true = Scope.has_permission?(scope, "content_management")

    attrs =
      from(t in Tag, where: t.school_id == ^scope.school_id)
      |> set_position_in_attrs(attrs)

    with {:ok, tag = %Tag{}} <-
           %Tag{}
           |> Tag.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_tag(scope, {:created, tag})
      {:ok, tag}
    end
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(scope, tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(scope, tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Scope{} = scope, %Tag{} = tag, attrs) do
    true = Scope.has_permission?(scope, "content_management")
    true = Scope.belongs_to_school?(scope, tag.school_id)

    with {:ok, tag = %Tag{}} <-
           tag
           |> Tag.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_tag(scope, {:updated, tag})
      {:ok, tag}
    end
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(scope, tag)
      {:ok, %Tag{}}

      iex> delete_tag(scope, tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(%Scope{} = scope, %Tag{} = tag) do
    true = Scope.has_permission?(scope, "content_management")
    true = Scope.belongs_to_school?(scope, tag.school_id)

    with {:ok, tag = %Tag{}} <-
           Repo.delete(tag) do
      broadcast_tag(scope, {:deleted, tag})
      {:ok, tag}
    end
  end

  @doc """
  Update lesson tag positions based on ids list order.

  ## Examples

      iex> update_lesson_tag_positions([3, 2, 1])
      :ok

  """
  @spec update_lesson_tag_positions(tags_ids :: [pos_integer()]) ::
          :ok | {:error, String.t()}
  def update_lesson_tag_positions(tags_ids),
    do: update_positions(Tag, tags_ids)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(scope, tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  def change_tag(%Scope{} = scope, %Tag{} = tag, attrs \\ %{}) do
    true = Scope.has_permission?(scope, "content_management")

    Tag.changeset(tag, attrs, scope)
  end
end
