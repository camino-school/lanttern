defmodule Lanttern.SchoolConfig do
  @moduledoc """
  The SchoolConfig context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.SchoolConfig.MomentCardTemplate

  @doc """
  Returns the list of moment_cards_templates.

  ## Examples

      iex> list_moment_cards_templates()
      [%MomentCardTemplate{}, ...]

  """
  def list_moment_cards_templates do
    Repo.all(MomentCardTemplate)
  end

  @doc """
  Gets a single moment_card_template.

  Raises `Ecto.NoResultsError` if the Moment card template does not exist.

  ## Examples

      iex> get_moment_card_template!(123)
      %MomentCardTemplate{}

      iex> get_moment_card_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_moment_card_template!(id), do: Repo.get!(MomentCardTemplate, id)

  @doc """
  Creates a moment_card_template.

  ## Examples

      iex> create_moment_card_template(%{field: value})
      {:ok, %MomentCardTemplate{}}

      iex> create_moment_card_template(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_moment_card_template(attrs \\ %{}) do
    %MomentCardTemplate{}
    |> MomentCardTemplate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a moment_card_template.

  ## Examples

      iex> update_moment_card_template(moment_card_template, %{field: new_value})
      {:ok, %MomentCardTemplate{}}

      iex> update_moment_card_template(moment_card_template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_moment_card_template(%MomentCardTemplate{} = moment_card_template, attrs) do
    moment_card_template
    |> MomentCardTemplate.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a moment_card_template.

  ## Examples

      iex> delete_moment_card_template(moment_card_template)
      {:ok, %MomentCardTemplate{}}

      iex> delete_moment_card_template(moment_card_template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_moment_card_template(%MomentCardTemplate{} = moment_card_template) do
    Repo.delete(moment_card_template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking moment_card_template changes.

  ## Examples

      iex> change_moment_card_template(moment_card_template)
      %Ecto.Changeset{data: %MomentCardTemplate{}}

  """
  def change_moment_card_template(%MomentCardTemplate{} = moment_card_template, attrs \\ %{}) do
    MomentCardTemplate.changeset(moment_card_template, attrs)
  end
end
