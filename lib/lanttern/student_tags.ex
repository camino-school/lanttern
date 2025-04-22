defmodule Lanttern.StudentTags do
  @moduledoc """
  The StudentTags context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo
  alias Lanttern.StudentTags.Tag

  @doc """
  Returns the list of student_tags.

  ## Options

  - `:school_id` - filter results by school

  ## Examples

      iex> list_student_tags()
      [%Tag{}, ...]

  """
  def list_student_tags(opts \\ []) do
    from(
      t in Tag,
      order_by: t.position
    )
    |> apply_list_student_tags_opts(opts)
    |> Repo.all()
  end

  defp apply_list_student_tags_opts(queryable, []), do: queryable

  defp apply_list_student_tags_opts(queryable, [{:school_id, school_id} | opts]) do
    from(
      t in queryable,
      where: t.school_id == ^school_id
    )
    |> apply_list_student_tags_opts(opts)
  end

  defp apply_list_student_tags_opts(queryable, [_ | opts]),
    do: apply_list_student_tags_opts(queryable, opts)

  @doc """
  Gets a single student_tag.

  Raises `Ecto.NoResultsError` if the Student tag does not exist.

  ## Examples

      iex> get_student_tag!(123)
      %Tag{}

      iex> get_student_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Creates a student_tag.

  ## Examples

      iex> create_student_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_student_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_tag(attrs \\ %{}) do
    queryable =
      case attrs do
        %{school_id: school_id} when not is_nil(school_id) ->
          from(t in Tag, where: t.school_id == ^school_id)

        %{"school_id" => school_id} when not is_nil(school_id) ->
          from(t in Tag, where: t.school_id == ^school_id)

        _ ->
          Tag
      end

    attrs = set_position_in_attrs(queryable, attrs)

    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_tag.

  ## Examples

      iex> update_student_tag(student_tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_student_tag(student_tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_tag(%Tag{} = student_tag, attrs) do
    student_tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_tag.

  ## Examples

      iex> delete_student_tag(student_tag)
      {:ok, %Tag{}}

      iex> delete_student_tag(student_tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_tag(%Tag{} = student_tag) do
    Repo.delete(student_tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_tag changes.

  ## Examples

      iex> change_student_tag(student_tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  def change_student_tag(%Tag{} = student_tag, attrs \\ %{}) do
    Tag.changeset(student_tag, attrs)
  end

  @doc """
  Update student tags positions based on ids list order.

  ## Examples

      iex> update_student_tags_positions([3, 2, 1])
      :ok

  """
  @spec update_student_tags_positions([integer()]) :: :ok | {:error, String.t()}
  def update_student_tags_positions(tags_ids), do: update_positions(Tag, tags_ids)
end
