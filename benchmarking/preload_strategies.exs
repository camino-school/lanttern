defmodule Lanttern.Benchmarking.PreloadStrategies do
  # this is a simple implementation of the list function
  # preloading the fields in the same list query.
  # looking at Benchee results, when we have the assessment_point_id option
  # the preload in query strategy is ~2x faster - but when we don't have
  # this option, the preload in query strategy is ~1.2x slower 🙃
  # needs more investigation, but I'll keep this benchmark file here for now

  import Ecto.Query, warn: false
  alias Lanttern.Repo
  alias Lanttern.Assessments.AssessmentPointEntry

  def list_assessment_point_entries(opts \\ []) do
    AssessmentPointEntry
    |> maybe_filter_entries_by_assessment_point(opts)
    |> preload_before(opts)
    |> Repo.all()
  end

  defp preload_before(query, opts) do
    Enum.reduce(opts, query, fn {k, v}, query ->
      preload_before(query, k, v)
    end)
  end

  defp preload_before(query, :preloads, [:student, :ordinal_value]) do
    from(
      e in query,
      join: s in assoc(e, :student),
      left_join: ov in assoc(e, :ordinal_value),
      preload: [student: s, ordinal_value: ov]
    )
  end

  defp preload_before(query, _, _), do: query

  defp maybe_filter_entries_by_assessment_point(assessment_point_entry_query, opts) do
    case Keyword.get(opts, :assessment_point_id) do
      nil ->
        assessment_point_entry_query

      assessment_point_id ->
        from(
          e in assessment_point_entry_query,
          join: ap in assoc(e, :assessment_point),
          where: ap.id == ^assessment_point_id
        )
    end
  end
end

# when not using assessment_point_id opt, the Repo.preload strategy is faster
Benchee.run(
  %{
    "preload in query (no assessment point filter)" => fn ->
      Lanttern.Benchmarking.PreloadStrategies.list_assessment_point_entries(
        preloads: [:student, :ordinal_value]
      )
    end,
    "preload after with Repo.preload (no assessment point filter)" => fn ->
      Lanttern.Assessments.list_assessment_point_entries(
        preloads: [:student, :ordinal_value]
      )
    end
  }
)

# Benchee.run(
#   %{
#     "preload in query" => fn ->
#       Lanttern.Benchmarking.PreloadStrategies.list_assessment_point_entries(
#         preloads: [:student, :ordinal_value],
#         assessment_point_id: 3
#       )
#     end,
#     "preload after with Repo.preload" => fn ->
#       Lanttern.Assessments.list_assessment_point_entries(
#         preloads: [:student, :ordinal_value],
#         assessment_point_id: 3
#       )
#     end
#   }
# )
