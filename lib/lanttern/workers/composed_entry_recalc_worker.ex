defmodule Lanttern.Workers.ComposedEntryRecalcWorker do
  @moduledoc """
  Oban worker that recalculates composed assessment point entries after a
  batch save of component entries.

  Enqueued from `Lanttern.Assessments.save_assessment_point_entries/2` when
  any of the saved entries belong to assessment points that are components
  of a composed (sum or average) assessment point.

  ## Job arguments

  - `pairs` — list of `[parent_id, student_id]` pairs to recalculate
  - `domain` — `"teacher_entry"` or `"student_entry"`, the edit domain
  - `profile_id` — profile that triggered the save, used for audit logging
  """

  use Oban.Worker, queue: :assessments, max_attempts: 3, unique: true

  alias Lanttern.AssessmentComposition
  alias Lanttern.Identity.Scope

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{"pairs" => raw_pairs, "domain" => domain_str} = args

    pairs = Enum.map(raw_pairs, fn [parent_id, student_id] -> {parent_id, student_id} end)
    domain = String.to_existing_atom(domain_str)
    scope = %Scope{profile_id: args["profile_id"]}

    AssessmentComposition.recalculate_composed_entries(scope, pairs, domain)
  end
end
