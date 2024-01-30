defmodule Lanttern.Moments do
  @moduledoc """
  The Moments context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Moments.MomentCard

  @doc """
  Returns the list of moment_cards.

  ## Examples

      iex> list_moment_cards()
      [%MomentCard{}, ...]

  """
  def list_moment_cards do
    Repo.all(MomentCard)
  end

  @doc """
  Gets a single moment_card.

  Raises `Ecto.NoResultsError` if the Moment card does not exist.

  ## Examples

      iex> get_moment_card!(123)
      %MomentCard{}

      iex> get_moment_card!(456)
      ** (Ecto.NoResultsError)

  """
  def get_moment_card!(id), do: Repo.get!(MomentCard, id)

  @doc """
  Creates a moment_card.

  ## Examples

      iex> create_moment_card(%{field: value})
      {:ok, %MomentCard{}}

      iex> create_moment_card(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_moment_card(attrs \\ %{}) do
    %MomentCard{}
    |> MomentCard.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a moment_card.

  ## Examples

      iex> update_moment_card(moment_card, %{field: new_value})
      {:ok, %MomentCard{}}

      iex> update_moment_card(moment_card, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_moment_card(%MomentCard{} = moment_card, attrs) do
    moment_card
    |> MomentCard.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a moment_card.

  ## Examples

      iex> delete_moment_card(moment_card)
      {:ok, %MomentCard{}}

      iex> delete_moment_card(moment_card)
      {:error, %Ecto.Changeset{}}

  """
  def delete_moment_card(%MomentCard{} = moment_card) do
    Repo.delete(moment_card)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking moment_card changes.

  ## Examples

      iex> change_moment_card(moment_card)
      %Ecto.Changeset{data: %MomentCard{}}

  """
  def change_moment_card(%MomentCard{} = moment_card, attrs \\ %{}) do
    MomentCard.changeset(moment_card, attrs)
  end
end
