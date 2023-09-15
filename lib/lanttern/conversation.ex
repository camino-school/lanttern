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

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments(opts \\ []) do
    Repo.all(Comment)
    |> maybe_preload(opts)
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

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
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

  ## Examples

      iex> create_feedback_comment(%{comment: "blah", profile_id: 1}, feedback_id)
      {:ok, %Comment{}}

      iex> create_feedback_comment(%{comment: "blah", profile_id: nil}, feedback_id)
      {:error, %Ecto.Changeset{}}

      iex> create_feedback_comment(%{comment: "blah", profile_id: 1}, bad_feedback_id)
      {:error, "Feedback not found"}

  """
  def create_feedback_comment(comment_attrs, feedback_id) do
    Repo.transaction(fn ->
      {:ok, comment} = create_comment(comment_attrs)

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
