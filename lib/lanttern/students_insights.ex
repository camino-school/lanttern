defmodule Lanttern.StudentsInsights do
  @moduledoc """
  The StudentsInsights context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Identity.User
  alias Lanttern.Schools.Student
  alias Lanttern.StudentsInsights.StudentInsight
  alias Lanttern.Utils

  @doc """
  Returns the list of student_insights for the current user's school.

  ## Options

  - `:author_id` - filter results by author (staff member)
  - `:preloads` - preloads associated data

  ## Examples

      iex> list_student_insights(current_user, [])
      [%StudentInsight{}, ...]

  """
  @type list_student_insights_opts ::
          [
            author_id: pos_integer(),
            preloads: list()
          ]
  @spec list_student_insights(current_user :: User.t(), list_student_insights_opts()) :: [
          StudentInsight.t()
        ]
  def list_student_insights(%User{current_profile: current_profile}, opts \\ []) do
    from(si in StudentInsight,
      where: si.school_id == ^current_profile.school_id,
      order_by: [desc: si.inserted_at]
    )
    |> apply_list_student_insights_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_student_insights_opts(queryable, []), do: queryable

  defp apply_list_student_insights_opts(queryable, [{:author_id, author_id} | opts]) do
    from(
      si in queryable,
      where: si.author_id == ^author_id
    )
    |> apply_list_student_insights_opts(opts)
  end

  defp apply_list_student_insights_opts(queryable, [_ | opts]),
    do: apply_list_student_insights_opts(queryable, opts)

  @doc """
  Gets a single student_insight scoped to the current user's school.

  Returns `nil` if the student insight does not exist or doesn't belong to user's school.

  ## Options

  - `:preloads` - preloads associated data

  ## Examples

      iex> get_student_insight(current_user, 123)
      %StudentInsight{}

      iex> get_student_insight(current_user, 456)
      nil

  """
  @spec get_student_insight(current_user :: User.t(), pos_integer(), Keyword.t()) ::
          StudentInsight.t() | nil
  def get_student_insight(%User{current_profile: current_profile}, id, opts \\ []) do
    from(si in StudentInsight, where: si.school_id == ^current_profile.school_id)
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single student_insight scoped to the current user's school.

  Same as `get_student_insight/3`, but raises `Ecto.NoResultsError` if the `StudentInsight` does not exist.

  """
  @spec get_student_insight!(current_user :: User.t(), pos_integer(), Keyword.t()) ::
          StudentInsight.t()
  def get_student_insight!(%User{current_profile: current_profile}, id, opts \\ []) do
    from(si in StudentInsight, where: si.school_id == ^current_profile.school_id)
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a student_insight with the current user as author.

  ## Examples

      iex> create_student_insight(current_user, %{description: "Great insight"})
      {:ok, %StudentInsight{}}

      iex> create_student_insight(current_user, %{description: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_insight(%User{} = current_user, attrs \\ %{}) do
    attrs = Utils.normalize_attrs_to_atom_keys(attrs)

    with {:ok, attrs} <- prepare_attrs_with_student(current_user, attrs) do
      %StudentInsight{}
      |> StudentInsight.changeset(attrs, current_user)
      |> Repo.insert()
    end
  end

  defp prepare_attrs_with_student(current_user, %{student_id: student_id} = attrs)
       when is_integer(student_id) do
    case get_student_for_school(current_user, student_id) do
      {:ok, _student} ->
        {:ok, attrs}

      {:error, :invalid_student} ->
        {:error,
         %Ecto.Changeset{}
         |> Ecto.Changeset.add_error(
           :student_id,
           gettext("student is invalid or from different school")
         )}
    end
  end

  defp prepare_attrs_with_student(_current_user, attrs) do
    if Map.has_key?(attrs, :student_id) do
      {:error,
       %Ecto.Changeset{}
       |> Ecto.Changeset.add_error(:student_id, gettext("student is required"))}
    else
      {:ok, attrs}
    end
  end

  @doc """
  Updates a student_insight.

  Only allows updates if the current user is the author of the insight.

  ## Examples

      iex> update_student_insight(current_user, student_insight, %{description: "Updated insight"})
      {:ok, %StudentInsight{}}

      iex> update_student_insight(current_user, other_user_insight, %{description: "Hack attempt"})
      {:error, :unauthorized}

  """
  @spec update_student_insight(User.t(), StudentInsight.t(), map()) ::
          {:ok, StudentInsight.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def update_student_insight(
        %User{} = current_user,
        %StudentInsight{} = student_insight,
        attrs
      ) do
    with :ok <- StudentInsight.validate_ownership(current_user, student_insight),
         attrs <- Utils.normalize_attrs_to_atom_keys(attrs),
         {:ok, attrs} <- prepare_attrs_with_student(current_user, attrs) do
      student_insight
      |> StudentInsight.changeset(attrs, current_user)
      |> Repo.update()
    end
  end

  @doc """
  Deletes a student_insight.

  Only allows deletion if the current user is the author of the insight.

  ## Examples

      iex> delete_student_insight(current_user, student_insight)
      {:ok, %StudentInsight{}}

      iex> delete_student_insight(current_user, other_user_insight)
      {:error, :unauthorized}

  """
  @spec delete_student_insight(User.t(), StudentInsight.t()) ::
          {:ok, StudentInsight.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def delete_student_insight(
        %User{} = current_user,
        %StudentInsight{} = student_insight
      ) do
    with :ok <- StudentInsight.validate_ownership(current_user, student_insight) do
      Repo.delete(student_insight)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_insight changes.

  ## Examples

      iex> change_student_insight(student_insight)
      %Ecto.Changeset{data: %StudentInsight{}}

  """
  def change_student_insight(
        %User{} = current_user,
        %StudentInsight{} = student_insight,
        attrs \\ %{}
      ) do
    StudentInsight.changeset(student_insight, attrs, current_user)
  end

  # Gets a student by ID ensuring it belongs to the current user's school.
  # Returns `{:ok, student}` if the student ID is valid and belongs to the school.
  # Returns `{:error, :invalid_student}` if the student doesn't exist or belongs to a different school.
  @spec get_student_for_school(User.t(), pos_integer()) ::
          {:ok, Student.t()} | {:error, :invalid_student}
  defp get_student_for_school(%User{current_profile: current_profile}, student_id) do
    student =
      from(s in Student,
        where: s.id == ^student_id and s.school_id == ^current_profile.school_id
      )
      |> Repo.one()

    case student do
      %Student{} = student -> {:ok, student}
      nil -> {:error, :invalid_student}
    end
  end
end
