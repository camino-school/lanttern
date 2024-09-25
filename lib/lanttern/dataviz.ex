defmodule Lanttern.Dataviz do
  @moduledoc """
  The Dataviz context.
  """

  import Ecto.Query, warn: false
  # import Lanttern.RepoHelpers

  alias Lanttern.Repo

  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.Strand

  @doc """
  Returns a map with required data to build the strand lanttern viz.

  - `strand_goals_curriculum_items` curriculum items will have preloaded curriculum components
  - `moments_assessments_curriculum_items_ids` will be ordered by moment and assessment point positions desc

  """
  @spec get_strand_lanttern_viz_data(strand_id :: pos_integer()) :: %{
          moments: [Moment.t()],
          strand_goals_curriculum_items: [CurriculumItem.t()],
          strand_goals_curriculum_items_ids: [pos_integer()],
          moments_assessments_curriculum_items_ids: [[pos_integer()]]
        }
  def get_strand_lanttern_viz_data(strand_id) do
    strand =
      from(
        s in Strand,
        join: ap in assoc(s, :assessment_points),
        join: ci in assoc(ap, :curriculum_item),
        join: cc in assoc(ci, :curriculum_component),
        join: m in assoc(s, :moments),
        join: m_ap in assoc(m, :assessment_points),
        where: s.id == ^strand_id,
        preload: [
          moments: {m, assessment_points: m_ap},
          assessment_points: {ap, curriculum_item: {ci, curriculum_component: cc}}
        ],
        order_by: [desc: m.position, desc: m_ap.position, asc: ap.position]
      )
      |> Repo.one()

    case strand do
      nil ->
        %{
          moments: [],
          strand_goals_curriculum_items: [],
          strand_goals_curriculum_items_ids: [],
          moments_assessments_curriculum_items_ids: []
        }

      %Strand{} ->
        moments =
          strand.moments
          # unload assessment points to save memory
          |> Enum.map(
            &Map.put(&1, :assessment_points, %Ecto.Association.NotLoaded{
              __field__: :assessment_points
            })
          )

        strand_goals_curriculum_items =
          strand.assessment_points
          |> Enum.map(& &1.curriculum_item)

        strand_goals_curriculum_item_ids =
          strand_goals_curriculum_items
          |> Enum.map(& &1.id)

        moments_assessments_curriculum_items_ids =
          strand.moments
          |> Enum.map(&map_moment_assessment_points_to_curriculum_item_ids(&1))

        %{
          moments: moments,
          strand_goals_curriculum_items: strand_goals_curriculum_items,
          strand_goals_curriculum_items_ids: strand_goals_curriculum_item_ids,
          moments_assessments_curriculum_items_ids: moments_assessments_curriculum_items_ids
        }
    end
  end

  defp map_moment_assessment_points_to_curriculum_item_ids(%Moment{
         assessment_points: assessment_points
       }),
       do: Enum.map(assessment_points, & &1.curriculum_item_id)
end
