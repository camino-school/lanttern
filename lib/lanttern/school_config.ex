defmodule Lanttern.SchoolConfig do
  @moduledoc """
  The SchoolConfig context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.Identity.Scope
  alias Lanttern.SchoolConfig.MomentCardTemplate

  @doc """
  Returns the list of moment_cards_templates.

  ## Examples

      iex> list_moment_cards_templates(scope)
      [%MomentCardTemplate{}, ...]

  """
  def list_moment_cards_templates(%Scope{} = scope) do
    from(
      mct in MomentCardTemplate,
      where: mct.school_id == ^scope.school_id,
      order_by: mct.position
    )
    |> Repo.all()
  end

  @doc """
  Gets a single moment_card_template.

  Returns `nil` if the Moment card template does not exist.

  ## Examples

      iex> get_moment_card_template(scope, 123)
      %MomentCardTemplate{}

      iex> get_moment_card_template(scope, 456)
      nil

  """
  def get_moment_card_template(%Scope{} = scope, id) do
    Repo.get_by(MomentCardTemplate, id: id, school_id: scope.school_id)
  end

  @doc """
  Same as get_moment_card_template/1, but raises `Ecto.NoResultsError` if the Moment card template does not exist.

  ## Examples

      iex> get_moment_card_template!(scope, 123)
      %MomentCardTemplate{}

      iex> get_moment_card_template!(scope, 456)
      ** (Ecto.NoResultsError)
  """
  def get_moment_card_template!(%Scope{} = scope, id) do
    Repo.get_by!(MomentCardTemplate, id: id, school_id: scope.school_id)
  end

  @doc """
  Creates a moment_card_template.

  ## Examples

      iex> create_moment_card_template(scope, %{field: value})
      {:ok, %MomentCardTemplate{}}

      iex> create_moment_card_template(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_moment_card_template(%Scope{} = scope, attrs \\ %{}) do
    true = Scope.has_permission?(scope, "content_management")

    queryable =
      from(
        mct in MomentCardTemplate,
        where: mct.school_id == ^scope.school_id
      )

    attrs = set_position_in_attrs(queryable, attrs)

    %MomentCardTemplate{}
    |> MomentCardTemplate.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a moment_card_template.

  ## Examples

      iex> update_moment_card_template(scope, moment_card_template, %{field: new_value})
      {:ok, %MomentCardTemplate{}}

      iex> update_moment_card_template(scope, moment_card_template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_moment_card_template(
        %Scope{} = scope,
        %MomentCardTemplate{} = moment_card_template,
        attrs
      ) do
    true = Scope.belongs_to_school?(scope, moment_card_template.school_id)
    true = Scope.has_permission?(scope, "content_management")

    moment_card_template
    |> MomentCardTemplate.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a moment_card_template.

  ## Examples

      iex> delete_moment_card_template(scope, moment_card_template)
      {:ok, %MomentCardTemplate{}}

      iex> delete_moment_card_template(scope, moment_card_template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_moment_card_template(%Scope{} = scope, %MomentCardTemplate{} = moment_card_template) do
    true = Scope.belongs_to_school?(scope, moment_card_template.school_id)
    true = Scope.has_permission?(scope, "content_management")

    Repo.delete(moment_card_template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking moment_card_template changes.

  ## Examples

      iex> change_moment_card_template(scope, moment_card_template)
      %Ecto.Changeset{data: %MomentCardTemplate{}}

  """
  def change_moment_card_template(
        %Scope{} = scope,
        %MomentCardTemplate{} = moment_card_template,
        attrs \\ %{}
      ) do
    true = Scope.belongs_to_school?(scope, moment_card_template.school_id)
    true = Scope.has_permission?(scope, "content_management")

    MomentCardTemplate.changeset(moment_card_template, attrs, scope)
  end

  @doc """
  Update moment cards templates positions based on ids list order.

  ## Examples

  iex> update_moment_cards_templates_positions([3, 2, 1])
  :ok

  """
  @spec update_moment_cards_templates_positions(moment_cards_templates_ids :: [pos_integer()]) ::
          :ok | {:error, String.t()}
  def update_moment_cards_templates_positions(moment_cards_templates_ids),
    do: update_positions(MomentCardTemplate, moment_cards_templates_ids)
end
