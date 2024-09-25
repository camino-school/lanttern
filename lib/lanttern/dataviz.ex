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

  @color_scale [
    # cyan
    "#67e8f9",
    # rose
    "#fda4af",
    # violet
    "#c4b5fd",
    # yellow
    "#fde047",
    # lime
    "#bef264",
    # blue
    "#93c5fd",
    # fuschia
    "#f0abfc",
    # orange
    "#fdba74"
  ]

  @doc """
  Returns a map with required data to build the strand lanttern viz.

  - `strand_goals_curriculum_items` curriculum items will have preloaded curriculum components
  - `moments_assessments_curriculum_items_ids` will be ordered by moment and assessment point positions desc
  - `curriculum_items_ids_color_map` is a map with curriculum item id as key and a color (from the color scale) as value

  """
  @spec get_strand_lanttern_viz_data(strand_id :: pos_integer()) :: %{
          moments: [Moment.t()],
          strand_goals_curriculum_items: [CurriculumItem.t()],
          strand_goals_curriculum_items_ids: [pos_integer()],
          moments_assessments_curriculum_items_ids: [[pos_integer()]],
          curriculum_items_ids_color_map: map()
        }
  def get_strand_lanttern_viz_data(strand_id) do
    strand =
      from(
        s in Strand,
        join: ap in assoc(s, :assessment_points),
        join: ci in assoc(ap, :curriculum_item),
        join: cc in assoc(ci, :curriculum_component),
        left_join: m in assoc(s, :moments),
        left_join: m_ap in assoc(m, :assessment_points),
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
          moments_assessments_curriculum_items_ids: [],
          curriculum_items_ids_color_map: %{}
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

        curriculum_items_ids_color_map =
          strand_goals_curriculum_item_ids
          |> Enum.with_index()
          |> Enum.map(fn {ci_id, i} ->
            {ci_id, Enum.at(@color_scale, rem(i, length(@color_scale)))}
          end)
          |> Enum.into(%{})

        %{
          moments: moments,
          strand_goals_curriculum_items: strand_goals_curriculum_items,
          strand_goals_curriculum_items_ids: strand_goals_curriculum_item_ids,
          moments_assessments_curriculum_items_ids: moments_assessments_curriculum_items_ids,
          curriculum_items_ids_color_map: curriculum_items_ids_color_map
        }
    end
  end

  defp map_moment_assessment_points_to_curriculum_item_ids(%Moment{
         assessment_points: assessment_points
       }),
       do: Enum.map(assessment_points, & &1.curriculum_item_id)
end
