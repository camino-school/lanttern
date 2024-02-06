defmodule Lanttern.Reporting do
  @moduledoc """
  The Reporting context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.Reporting.ReportCard

  @doc """
  Returns the list of report_cards.

  ## Examples

      iex> list_report_cards()
      [%ReportCard{}, ...]

  """
  def list_report_cards do
    Repo.all(ReportCard)
  end

  @doc """
  Gets a single report_card.

  Raises `Ecto.NoResultsError` if the Report card does not exist.

  ## Options:

      - `:preloads` – preloads associated data

  ## Examples

      iex> get_report_card!(123)
      %ReportCard{}

      iex> get_report_card!(456)
      ** (Ecto.NoResultsError)

  """
  def get_report_card!(id, opts \\ []) do
    ReportCard
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a report_card.

  ## Examples

      iex> create_report_card(%{field: value})
      {:ok, %ReportCard{}}

      iex> create_report_card(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_report_card(attrs \\ %{}) do
    %ReportCard{}
    |> ReportCard.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a report_card.

  ## Examples

      iex> update_report_card(report_card, %{field: new_value})
      {:ok, %ReportCard{}}

      iex> update_report_card(report_card, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_report_card(%ReportCard{} = report_card, attrs) do
    report_card
    |> ReportCard.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a report_card.

  ## Examples

      iex> delete_report_card(report_card)
      {:ok, %ReportCard{}}

      iex> delete_report_card(report_card)
      {:error, %Ecto.Changeset{}}

  """
  def delete_report_card(%ReportCard{} = report_card) do
    Repo.delete(report_card)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking report_card changes.

  ## Examples

      iex> change_report_card(report_card)
      %Ecto.Changeset{data: %ReportCard{}}

  """
  def change_report_card(%ReportCard{} = report_card, attrs \\ %{}) do
    ReportCard.changeset(report_card, attrs)
  end

  alias Lanttern.Reporting.StrandReport

  @doc """
  Returns the list of strand_reports.

  ## Examples

      iex> list_strand_reports()
      [%StrandReport{}, ...]

  """
  def list_strand_reports do
    Repo.all(StrandReport)
  end

  @doc """
  Gets a single strand_report.

  Raises `Ecto.NoResultsError` if the Strand report does not exist.

  ## Examples

      iex> get_strand_report!(123)
      %StrandReport{}

      iex> get_strand_report!(456)
      ** (Ecto.NoResultsError)

  """
  def get_strand_report!(id), do: Repo.get!(StrandReport, id)

  @doc """
  Creates a strand_report.

  ## Examples

      iex> create_strand_report(%{field: value})
      {:ok, %StrandReport{}}

      iex> create_strand_report(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_strand_report(attrs \\ %{}) do
    %StrandReport{}
    |> StrandReport.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a strand_report.

  ## Examples

      iex> update_strand_report(strand_report, %{field: new_value})
      {:ok, %StrandReport{}}

      iex> update_strand_report(strand_report, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_strand_report(%StrandReport{} = strand_report, attrs) do
    strand_report
    |> StrandReport.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a strand_report.

  ## Examples

      iex> delete_strand_report(strand_report)
      {:ok, %StrandReport{}}

      iex> delete_strand_report(strand_report)
      {:error, %Ecto.Changeset{}}

  """
  def delete_strand_report(%StrandReport{} = strand_report) do
    Repo.delete(strand_report)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking strand_report changes.

  ## Examples

      iex> change_strand_report(strand_report)
      %Ecto.Changeset{data: %StrandReport{}}

  """
  def change_strand_report(%StrandReport{} = strand_report, attrs \\ %{}) do
    StrandReport.changeset(strand_report, attrs)
  end
end
