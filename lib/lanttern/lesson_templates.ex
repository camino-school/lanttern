defmodule Lanttern.LessonTemplates do
  @moduledoc """
  The LessonTemplates context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Identity.Scope
  alias Lanttern.LessonTemplates.LessonTemplate

  @doc """
  Returns the list of lesson_templates.

  ## Examples

      iex> list_lesson_templates(scope)
      [%LessonTemplate{}, ...]

  """
  def list_lesson_templates(%Scope{} = scope) do
    from(
      lt in LessonTemplate,
      where: lt.school_id == ^scope.school_id,
      order_by: [asc: :name]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single lesson_template.

  Raises `Ecto.NoResultsError` if the Lesson template does not exist.

  ## Examples

      iex> get_lesson_template!(scope, 123)
      %LessonTemplate{}

      iex> get_lesson_template!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_lesson_template!(%Scope{} = scope, id) do
    Repo.get_by!(LessonTemplate, id: id, school_id: scope.school_id)
  end

  @doc """
  Creates a lesson_template.

  ## Examples

      iex> create_lesson_template(scope, %{field: value})
      {:ok, %LessonTemplate{}}

      iex> create_lesson_template(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_lesson_template(%Scope{} = scope, attrs) do
    true = Scope.has_permission?(scope, "content_management")

    %LessonTemplate{}
    |> LessonTemplate.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a lesson_template.

  ## Examples

      iex> update_lesson_template(scope, lesson_template, %{field: new_value})
      {:ok, %LessonTemplate{}}

      iex> update_lesson_template(scope, lesson_template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_lesson_template(%Scope{} = scope, %LessonTemplate{} = lesson_template, attrs) do
    true = Scope.has_permission?(scope, "content_management")
    true = Scope.belongs_to_school?(scope, lesson_template.school_id)

    lesson_template
    |> LessonTemplate.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a lesson_template.

  ## Examples

      iex> delete_lesson_template(scope, lesson_template)
      {:ok, %LessonTemplate{}}

      iex> delete_lesson_template(scope, lesson_template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_lesson_template(%Scope{} = scope, %LessonTemplate{} = lesson_template) do
    true = Scope.has_permission?(scope, "content_management")
    true = Scope.belongs_to_school?(scope, lesson_template.school_id)

    Repo.delete(lesson_template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking lesson_template changes.

  ## Examples

      iex> change_lesson_template(scope, lesson_template)
      %Ecto.Changeset{data: %LessonTemplate{}}

  """
  def change_lesson_template(%Scope{} = scope, %LessonTemplate{} = lesson_template, attrs \\ %{}) do
    true = Scope.has_permission?(scope, "content_management")
    true = Scope.belongs_to_school?(scope, lesson_template.school_id)

    LessonTemplate.changeset(lesson_template, attrs, scope)
  end
end
