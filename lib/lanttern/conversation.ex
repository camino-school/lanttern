defmodule Lanttern.Conversation do
  @moduledoc """
  The Conversation context.
  """

  import Ecto.Query, warn: false

  import Lanttern.RepoHelpers
  alias Lanttern.Repo
  alias Lanttern.Conversation.Comment

  @doc """
  Returns the list of comments.

  ### Options:

  `:preloads` – preloads associated data
  `:feedback_id` – filter comments by feedback

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments(opts \\ []) do
    from(
      c in Comment,
      order_by: [asc: c.inserted_at]
    )
    |> maybe_filter_comments_by_feedback(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp maybe_filter_comments_by_feedback(comments_query, opts) do
    case Keyword.get(opts, :feedback_id) do
      nil ->
        comments_query

      feedback_id ->
        from(
          c in comments_query,
          join: f in assoc(c, :feedback),
          where: f.id == ^feedback_id
        )
    end
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id, opts \\ []) do
    Repo.get!(Comment, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a comment.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}, opts \\ []) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
    |> maybe_preload(opts)
  end

  @doc """
  Updates a comment.

  ### Options:

  The second argument for `Repo.update/2`.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs, opts \\ []) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update(opts)
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  @doc """
  Creates a feedback comment.

  If `mark_feedback_id_for_completion` is present in `comment_attrs`,
  will add the created comment to `Feedback`'s `completion_comment`.

  See `create_comment/2` for `opts`.

  ## Examples

      iex> create_feedback_comment(%{comment: "good comment", profile_id: 1}, 1)
      {:ok, %Comment{}}

      iex> create_feedback_comment(%{comment: "no profile", profile_id: nil}, 1)
      {:error, %Ecto.Changeset{}}

      iex> create_feedback_comment(%{comment: "non existing feedback", profile_id: 1}, 2)
      {:error, "Feedback not found"}

  """
  def create_feedback_comment(comment_attrs, feedback_id, opts \\ []) do
    Repo.transaction(fn ->
      comment =
        case create_comment(comment_attrs, opts) do
          {:ok, comment} -> comment
          {:error, error_changeset} -> Repo.rollback(error_changeset)
        end

      try do
        {1, _} =
          Repo.insert_all("feedback_comments", [
            [feedback_id: feedback_id, comment_id: comment.id]
          ])
      rescue
        Postgrex.Error -> Repo.rollback("Feedback not found")
      end

      comment
    end)
  end
end
