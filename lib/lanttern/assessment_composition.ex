defmodule Lanttern.AssessmentComposition do
  @moduledoc """
  The AssessmentComposition context.

  Manages `Component` records that link child assessment points into a
  composed (parent) assessment point for sum or average grading.
  """

  import Ecto.Query

  alias Lanttern.Repo

  alias Lanttern.AssessmentComposition.Component
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Identity.Scope

  @doc """
  Returns the list of composition components for the given parent assessment point id.

  Child assessment points are preloaded with scale and curriculum item.
  """
  def list_assessment_point_components(%Scope{} = _scope, parent_id) do
    from(c in Component,
      join: ap in AssessmentPoint,
      on: c.component_id == ap.id,
      where: c.parent_id == ^parent_id,
      order_by: [asc_nulls_last: ap.moment_id, asc: ap.position]
    )
    |> Repo.all()
    |> Repo.preload(component: [:scale, curriculum_item: :curriculum_component])
  end

  @doc """
  Creates an assessment point composition component.

  ## Examples

      iex> create_assessment_point_component(scope, %{parent_id: 1, component_id: 2})
      {:ok, %Component{}}

      iex> create_assessment_point_component(scope, %{})
      {:error, %Ecto.Changeset{}}

  """
  def create_assessment_point_component(%Scope{} = scope, attrs \\ %{}) do
    true = Scope.profile_type?(scope, "staff")

    %Component{}
    |> Component.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an assessment point composition component.

  ## Examples

      iex> update_assessment_point_component(scope, component, %{weight: 2.0})
      {:ok, %Component{}}

      iex> update_assessment_point_component(scope, component, %{weight: -1.0})
      {:error, %Ecto.Changeset{}}

  """
  def update_assessment_point_component(%Scope{} = scope, %Component{} = component, attrs) do
    true = Scope.profile_type?(scope, "staff")

    component
    |> Component.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an assessment point composition component.
  """
  def delete_assessment_point_component(%Scope{} = scope, %Component{} = component) do
    true = Scope.profile_type?(scope, "staff")

    Repo.delete(component)
  end

  @doc """
  Deletes all composition components for the given parent assessment point id.
  """
  def delete_all_assessment_point_components(%Scope{} = scope, parent_id) do
    true = Scope.profile_type?(scope, "staff")

    from(c in Component, where: c.parent_id == ^parent_id)
    |> Repo.delete_all()

    :ok
  end
end
