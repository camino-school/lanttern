defmodule Lanttern.Quizzes do
  @moduledoc """
  The Quizzes context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Quizzes.Quiz
  alias Lanttern.Quizzes.QuizItem
  alias Lanttern.Quizzes.QuizItemAlternative

  @doc """
  Returns the list of quizzes.

  ## Examples

      iex> list_quizzes()
      [%Quiz{}, ...]

  """
  def list_quizzes do
    Repo.all(Quiz)
  end

  @doc """
  Gets a single quiz.

  Raises `Ecto.NoResultsError` if the Quiz does not exist.

  ## Examples

      iex> get_quiz!(123)
      %Quiz{}

      iex> get_quiz!(456)
      ** (Ecto.NoResultsError)

  """
  def get_quiz!(id), do: Repo.get!(Quiz, id)

  @doc """
  Creates a quiz.

  ## Examples

      iex> create_quiz(%{field: value})
      {:ok, %Quiz{}}

      iex> create_quiz(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_quiz(attrs \\ %{}) do
    %Quiz{}
    |> Quiz.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a quiz.

  ## Examples

      iex> update_quiz(quiz, %{field: new_value})
      {:ok, %Quiz{}}

      iex> update_quiz(quiz, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_quiz(%Quiz{} = quiz, attrs) do
    quiz
    |> Quiz.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a quiz.

  ## Examples

      iex> delete_quiz(quiz)
      {:ok, %Quiz{}}

      iex> delete_quiz(quiz)
      {:error, %Ecto.Changeset{}}

  """
  def delete_quiz(%Quiz{} = quiz) do
    Repo.delete(quiz)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking quiz changes.

  ## Examples

      iex> change_quiz(quiz)
      %Ecto.Changeset{data: %Quiz{}}

  """
  def change_quiz(%Quiz{} = quiz, attrs \\ %{}) do
    Quiz.changeset(quiz, attrs)
  end

  @doc """
  Returns the list of quiz_items.

  ## Examples

      iex> list_quiz_items()
      [%QuizItem{}, ...]

  """
  def list_quiz_items do
    Repo.all(QuizItem)
  end

  @doc """
  Gets a single quiz_item.

  Raises `Ecto.NoResultsError` if the Quiz item does not exist.

  ## Examples

      iex> get_quiz_item!(123)
      %QuizItem{}

      iex> get_quiz_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_quiz_item!(id), do: Repo.get!(QuizItem, id)

  @doc """
  Creates a quiz_item.

  ## Examples

      iex> create_quiz_item(%{field: value})
      {:ok, %QuizItem{}}

      iex> create_quiz_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_quiz_item(attrs \\ %{}) do
    %QuizItem{}
    |> QuizItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a quiz_item.

  ## Examples

      iex> update_quiz_item(quiz_item, %{field: new_value})
      {:ok, %QuizItem{}}

      iex> update_quiz_item(quiz_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_quiz_item(%QuizItem{} = quiz_item, attrs) do
    quiz_item
    |> QuizItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a quiz_item.

  ## Examples

      iex> delete_quiz_item(quiz_item)
      {:ok, %QuizItem{}}

      iex> delete_quiz_item(quiz_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_quiz_item(%QuizItem{} = quiz_item) do
    Repo.delete(quiz_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking quiz_item changes.

  ## Examples

      iex> change_quiz_item(quiz_item)
      %Ecto.Changeset{data: %QuizItem{}}

  """
  def change_quiz_item(%QuizItem{} = quiz_item, attrs \\ %{}) do
    QuizItem.changeset(quiz_item, attrs)
  end

  @doc """
  Returns the list of quiz_item_alternatives.

  ## Examples

      iex> list_quiz_item_alternatives()
      [%QuizItemAlternative{}, ...]

  """
  def list_quiz_item_alternatives do
    Repo.all(QuizItemAlternative)
  end

  @doc """
  Gets a single quiz_item_alternative.

  Raises `Ecto.NoResultsError` if the Quiz item alternative does not exist.

  ## Examples

      iex> get_quiz_item_alternative!(123)
      %QuizItemAlternative{}

      iex> get_quiz_item_alternative!(456)
      ** (Ecto.NoResultsError)

  """
  def get_quiz_item_alternative!(id), do: Repo.get!(QuizItemAlternative, id)

  @doc """
  Creates a quiz_item_alternative.

  ## Examples

      iex> create_quiz_item_alternative(%{field: value})
      {:ok, %QuizItemAlternative{}}

      iex> create_quiz_item_alternative(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_quiz_item_alternative(attrs \\ %{}) do
    %QuizItemAlternative{}
    |> QuizItemAlternative.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a quiz_item_alternative.

  ## Examples

      iex> update_quiz_item_alternative(quiz_item_alternative, %{field: new_value})
      {:ok, %QuizItemAlternative{}}

      iex> update_quiz_item_alternative(quiz_item_alternative, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_quiz_item_alternative(%QuizItemAlternative{} = quiz_item_alternative, attrs) do
    quiz_item_alternative
    |> QuizItemAlternative.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a quiz_item_alternative.

  ## Examples

      iex> delete_quiz_item_alternative(quiz_item_alternative)
      {:ok, %QuizItemAlternative{}}

      iex> delete_quiz_item_alternative(quiz_item_alternative)
      {:error, %Ecto.Changeset{}}

  """
  def delete_quiz_item_alternative(%QuizItemAlternative{} = quiz_item_alternative) do
    Repo.delete(quiz_item_alternative)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking quiz_item_alternative changes.

  ## Examples

      iex> change_quiz_item_alternative(quiz_item_alternative)
      %Ecto.Changeset{data: %QuizItemAlternative{}}

  """
  def change_quiz_item_alternative(%QuizItemAlternative{} = quiz_item_alternative, attrs \\ %{}) do
    QuizItemAlternative.changeset(quiz_item_alternative, attrs)
  end
end
