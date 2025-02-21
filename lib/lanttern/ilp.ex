defmodule Lanttern.ILP do
  @moduledoc """
  The ILP context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.ILP.ILPTemplate

  @doc """
  Returns the list of ilp_templates.

  ## Examples

      iex> list_ilp_templates()
      [%ILPTemplate{}, ...]

  """
  def list_ilp_templates do
    Repo.all(ILPTemplate)
  end

  @doc """
  Gets a single ilp_template.

  Raises `Ecto.NoResultsError` if the Ilp template does not exist.

  ## Examples

      iex> get_ilp_template!(123)
      %ILPTemplate{}

      iex> get_ilp_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ilp_template!(id), do: Repo.get!(ILPTemplate, id)

  @doc """
  Creates a ilp_template.

  ## Examples

      iex> create_ilp_template(%{field: value})
      {:ok, %ILPTemplate{}}

      iex> create_ilp_template(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ilp_template(attrs \\ %{}) do
    %ILPTemplate{}
    |> ILPTemplate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ilp_template.

  ## Examples

      iex> update_ilp_template(ilp_template, %{field: new_value})
      {:ok, %ILPTemplate{}}

      iex> update_ilp_template(ilp_template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ilp_template(%ILPTemplate{} = ilp_template, attrs) do
    ilp_template
    |> ILPTemplate.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ilp_template.

  ## Examples

      iex> delete_ilp_template(ilp_template)
      {:ok, %ILPTemplate{}}

      iex> delete_ilp_template(ilp_template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ilp_template(%ILPTemplate{} = ilp_template) do
    Repo.delete(ilp_template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ilp_template changes.

  ## Examples

      iex> change_ilp_template(ilp_template)
      %Ecto.Changeset{data: %ILPTemplate{}}

  """
  def change_ilp_template(%ILPTemplate{} = ilp_template, attrs \\ %{}) do
    ILPTemplate.changeset(ilp_template, attrs)
  end

  alias Lanttern.ILP.ILPSection

  @doc """
  Returns the list of ilp_sections.

  ## Examples

      iex> list_ilp_sections()
      [%ILPSection{}, ...]

  """
  def list_ilp_sections do
    Repo.all(ILPSection)
  end

  @doc """
  Gets a single ilp_section.

  Raises `Ecto.NoResultsError` if the Ilp section does not exist.

  ## Examples

      iex> get_ilp_section!(123)
      %ILPSection{}

      iex> get_ilp_section!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ilp_section!(id), do: Repo.get!(ILPSection, id)

  @doc """
  Creates a ilp_section.

  ## Examples

      iex> create_ilp_section(%{field: value})
      {:ok, %ILPSection{}}

      iex> create_ilp_section(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ilp_section(attrs \\ %{}) do
    %ILPSection{}
    |> ILPSection.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ilp_section.

  ## Examples

      iex> update_ilp_section(ilp_section, %{field: new_value})
      {:ok, %ILPSection{}}

      iex> update_ilp_section(ilp_section, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ilp_section(%ILPSection{} = ilp_section, attrs) do
    ilp_section
    |> ILPSection.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ilp_section.

  ## Examples

      iex> delete_ilp_section(ilp_section)
      {:ok, %ILPSection{}}

      iex> delete_ilp_section(ilp_section)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ilp_section(%ILPSection{} = ilp_section) do
    Repo.delete(ilp_section)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ilp_section changes.

  ## Examples

      iex> change_ilp_section(ilp_section)
      %Ecto.Changeset{data: %ILPSection{}}

  """
  def change_ilp_section(%ILPSection{} = ilp_section, attrs \\ %{}) do
    ILPSection.changeset(ilp_section, attrs)
  end
end
