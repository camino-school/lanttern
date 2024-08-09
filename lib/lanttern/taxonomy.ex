defmodule Lanttern.Taxonomy do
  @moduledoc """
  The Taxonomy context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Taxonomy.Subject
  alias Lanttern.Taxonomy.Year

  alias Lanttern.LearningContext.Strand

  @years [
    {"k0", "Kindergarten 0"},
    {"k1", "Kindergarten 1"},
    {"k2", "Kindergarten 2"},
    {"k3", "Kindergarten 3"},
    {"k4", "Kindergarten 4"},
    {"k5", "Kindergarten 5"},
    {"g1", "Grade 1"},
    {"g2", "Grade 2"},
    {"g3", "Grade 3"},
    {"g4", "Grade 4"},
    {"g5", "Grade 5"},
    {"g6", "Grade 6"},
    {"g7", "Grade 7"},
    {"g8", "Grade 8"},
    {"g9", "Grade 9"},
    {"g10", "Grade 10"},
    {"g11", "Grade 11"},
    {"g12", "Grade 12"}
  ]

  @subjects [
    {"engl", "English"},
    {"port", "Portuguese"},
    {"espa", "Spanish"},
    {"lang", "Languages"},
    {"hsci", "Human Science"},
    {"geog", "Geography"},
    {"hist", "History"},
    {"nsci", "Natural Science"},
    {"scie", "Science"},
    {"tech", "Technology"},
    {"engi", "Engineering"},
    {"math", "Math"},
    {"arts", "Arts"},
    {"vart", "Visual Arts"},
    {"dram", "Drama"},
    {"musi", "Music"},
    {"move", "Movement"},
    {"reli", "Religion"}
  ]

  @doc """
  Check if base years and subjects taxonomy already exists.
  """
  def has_base_taxonomy?() do
    db_year_codes =
      from(y in Year, select: [:code])
      |> Repo.all()
      |> Enum.map(& &1.code)

    db_subject_codes =
      from(s in Subject, select: [:code])
      |> Repo.all()
      |> Enum.map(& &1.code)

    has_all_base_years =
      Enum.map(@years, fn {code, _} -> code end)
      |> Enum.all?(fn code -> code in db_year_codes end)

    has_all_base_subjects =
      Enum.map(@subjects, fn {code, _} -> code end)
      |> Enum.all?(fn code -> code in db_subject_codes end)

    has_all_base_years and has_all_base_subjects
  end

  @doc """
  Creates base years and subjects taxonomy.
  """
  def seed_base_taxonomy() do
    @years
    |> Enum.each(fn {code, name} ->
      case Repo.get_by(Year, code: code) do
        nil -> Repo.insert!(%Year{code: code, name: name})
        _year -> nil
      end
    end)

    @subjects
    |> Enum.each(fn {code, name} ->
      case Repo.get_by(Subject, code: code) do
        nil -> Repo.insert!(%Subject{code: code, name: name})
        _subject -> nil
      end
    end)

    :ok
  end

  @doc """
  Returns the list of subjects ordered alphabetically.

  ### Options:

      - `:ids` – filter list by ids

  ### Examples

      iex> list_subjects()
      [%Subject{}, ...]

  """
  def list_subjects(opts \\ []) do
    from(
      sub in Subject,
      order_by: :name
    )
    |> filter_by_id(opts)
    |> Repo.all()
  end

  @doc """
  Returns the list of strand subjects ordered alphabetically.

  ## Examples

      iex> list_strand_subjects(1)
      {[%Subject{}, ...], [%Subject{}, ...]}

  """
  def list_strand_subjects(strand_id) do
    from(st in Strand,
      join: sub in assoc(st, :subjects),
      where: st.id == ^strand_id,
      order_by: sub.name,
      select: sub
    )
    |> Repo.all()
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

  ### Options:

      - `:ids` – filter list by ids

  ### Examples

      iex> list_years()
      [%Year{}, ...]

  """
  def list_years(opts \\ []) do
    from(
      y in Year,
      order_by: :id
    )
    |> filter_by_id(opts)
    |> Repo.all()
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

  # Helpers

  defp filter_by_id(query, opts) do
    case Keyword.get(opts, :ids) do
      nil ->
        query

      ids ->
        from(
          q in query,
          where: q.id in ^ids
        )
    end
  end
end
