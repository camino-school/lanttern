defmodule Lanttern.Taxonomy do
  @moduledoc """
  The Taxonomy context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Taxonomy.Subject
  alias Lanttern.Taxonomy.Year

  @doc """
  Returns the list of subjects ordered alphabetically.

  ## Examples

      iex> list_subjects()
      [%Subject{}, ...]

  """
  def list_subjects do
    from(
      sub in Subject,
      order_by: :name
    )
    |> Repo.all()
  end

  @doc """
  Returns a tuple with two lists of subjects:
  one comprised of subjects used by assessment points,
  and another with all the other subjects.

  Inferred through assesmsent points's curriculum-item.

  ## Examples

      iex> list_assessment_point_subjects()
      {[%Subject{}, ...], [%Subject{}, ...]}

  """
  def list_assessment_points_subjects do
    all_subjects =
      from(sub in Subject,
        left_join: ci in assoc(sub, :curriculum_items),
        left_join: ast in assoc(ci, :assessment_points),
        group_by: sub.id,
        order_by: sub.name,
        select: {sub, count(ast.id)}
      )
      |> Repo.all()
      |> Enum.group_by(fn {_subject, ast_count} -> ast_count > 0 end)

    {
      all_subjects |> Map.get(true, []) |> Enum.map(fn {sub, _} -> sub end),
      all_subjects |> Map.get(false, []) |> Enum.map(fn {sub, _} -> sub end)
    }
  end

  @doc """
  Gets a single subject.

  Raises `Ecto.NoResultsError` if the Subject does not exist.

  ## Examples

      iex> get_subject!(123)
      %Subject{}

      iex> get_subject!(456)
      ** (Ecto.NoResultsError)

  """
  def get_subject!(id), do: Repo.get!(Subject, id)

  @doc """
  Gets a single subject using the subject code.

  Raises `Ecto.NoResultsError` if the Subject does not exist.

  ## Examples

      iex> get_subject_by_code!("code")
      %Subject{}

      iex> get_subject_by_code!("wrong code")
      ** (Ecto.NoResultsError)

  """
  def get_subject_by_code!(code), do: Repo.get_by!(Subject, code: code)

  @doc """
  Creates a subject.

  ## Examples

      iex> create_subject(%{field: value})
      {:ok, %Subject{}}

      iex> create_subject(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subject(attrs \\ %{}) do
    %Subject{}
    |> Subject.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subject.

  ## Examples

      iex> update_subject(subject, %{field: new_value})
      {:ok, %Subject{}}

      iex> update_subject(subject, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subject(%Subject{} = subject, attrs) do
    subject
    |> Subject.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a subject.

  ## Examples

      iex> delete_subject(subject)
      {:ok, %Subject{}}

      iex> delete_subject(subject)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subject(%Subject{} = subject) do
    Repo.delete(subject)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subject changes.

  ## Examples

      iex> change_subject(subject)
      %Ecto.Changeset{data: %Subject{}}

  """
  def change_subject(%Subject{} = subject, attrs \\ %{}) do
    Subject.changeset(subject, attrs)
  end

  @doc """
  Returns a map with subjects codes as string keys and ids as values.

  Useful when we know the subject but we don't know the subject id in the current
  application env (e.g. curriculum items seeds).

  ## Examples

      iex> generate_subjects_code_id_map()
      %{"engl" => 1, "port" => 2, ...}

  """
  def generate_subjects_code_id_map do
    from(
      sub in Subject,
      select: {sub.code, sub.id}
    )
    |> Repo.all()
    |> Enum.into(%{})
  end

  @doc """
  Returns the list of years.

  ## Examples

      iex> list_years()
      [%Year{}, ...]

  """
  def list_years do
    Repo.all(Year)
  end

  @doc """
  Gets a single year.

  Raises `Ecto.NoResultsError` if the Year does not exist.

  ## Examples

      iex> get_year!(123)
      %Year{}

      iex> get_year!(456)
      ** (Ecto.NoResultsError)

  """
  def get_year!(id), do: Repo.get!(Year, id)

  @doc """
  Gets a single year using the year code.

  Raises `Ecto.NoResultsError` if the Year does not exist.

  ## Examples

      iex> get_year_by_code!("code")
      %Year{}

      iex> get_year_by_code!("wrong code")
      ** (Ecto.NoResultsError)

  """
  def get_year_by_code!(code), do: Repo.get_by!(Year, code: code)

  @doc """
  Creates a year.

  ## Examples

      iex> create_year(%{field: value})
      {:ok, %Year{}}

      iex> create_year(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_year(attrs \\ %{}) do
    %Year{}
    |> Year.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a year.

  ## Examples

      iex> update_year(year, %{field: new_value})
      {:ok, %Year{}}

      iex> update_year(year, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_year(%Year{} = year, attrs) do
    year
    |> Year.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a year.

  ## Examples

      iex> delete_year(year)
      {:ok, %Year{}}

      iex> delete_year(year)
      {:error, %Ecto.Changeset{}}

  """
  def delete_year(%Year{} = year) do
    Repo.delete(year)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking year changes.

  ## Examples

      iex> change_year(year)
      %Ecto.Changeset{data: %Year{}}

  """
  def change_year(%Year{} = year, attrs \\ %{}) do
    Year.changeset(year, attrs)
  end

  @doc """
  Returns a map with years codes as string keys and ids as values.

  Useful when we know the year but we don't know the id in the current
  application env (e.g. curriculum items seeds).

  ## Examples

      iex> generate_years_code_id_map()
      %{"k1" => 1, "k2" => 2, ...}

  """
  def generate_years_code_id_map do
    from(
      y in Year,
      select: {y.code, y.id}
    )
    |> Repo.all()
    |> Enum.into(%{})
  end
end
