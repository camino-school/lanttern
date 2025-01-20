defmodule Lanttern.SchoolConfig do
  @moduledoc """
  The SchoolConfig context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.SchoolConfig.MomentCardTemplate

  @doc """
  Returns the list of moment_cards_templates.

  ### Options:

  - `:school_id` – filter result by provided school id

  ## Examples

      iex> list_moment_cards_templates()
      [%MomentCardTemplate{}, ...]

  """
  def list_moment_cards_templates(opts \\ []) do
    from(
      mct in MomentCardTemplate,
      order_by: mct.position
    )
    |> apply_list_moment_cards_templates_opts(opts)
    |> Repo.all()
  end

  defp apply_list_moment_cards_templates_opts(queryable, []), do: queryable

  defp apply_list_moment_cards_templates_opts(queryable, [{:school_id, school_id} | opts]) do
    from(
      mct in queryable,
      where: mct.school_id == ^school_id
    )
    |> apply_list_moment_cards_templates_opts(opts)
  end

  defp apply_list_moment_cards_templates_opts(queryable, [_ | opts]),
    do: apply_list_moment_cards_templates_opts(queryable, opts)

  @doc """
  Gets a single moment_card_template.

  Returns `nil` if the Moment card template does not exist.

  ## Examples

      iex> get_moment_card_template(123)
      %MomentCardTemplate{}

      iex> get_moment_card_template(456)
      nil

  """
  def get_moment_card_template(id), do: Repo.get(MomentCardTemplate, id)

  @doc """
  Same as get_moment_card_template/1, but raises `Ecto.NoResultsError` if the Moment card template does not exist.

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
    queryable =
      case attrs do
        %{school_id: school_id} ->
          from(
            mct in MomentCardTemplate,
            where: mct.school_id == ^school_id
          )

        %{"school_id" => school_id} ->
          from(
            mct in MomentCardTemplate,
            where: mct.school_id == ^school_id
          )

        _ ->
          MomentCardTemplate
      end

    attrs = set_position_in_attrs(queryable, attrs)

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
