defmodule Lanttern.Seeds do
  @moduledoc """
  The Seeds context.

  One-time use on env setup.
  """

  import Ecto.Query, warn: false

  alias Lanttern.Repo
  alias Lanttern.Taxonomy.Year
  alias Lanttern.Taxonomy.Subject

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
  def check_base_taxonomy() do
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
end
