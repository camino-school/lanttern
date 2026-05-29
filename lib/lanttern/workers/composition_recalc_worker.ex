defmodule Lanttern.Workers.CompositionRecalcWorker do
  @moduledoc """
  Oban worker that recalculates all composed assessment point entries for a
  parent assessment point after its grade composition is created or updated.

  Enqueued from `Lanttern.AssessmentComposition.replace_assessment_point_components/3`
  so that existing entries (on both the component and parent assessment points)
  are brought up to date whenever the composition changes.

  ## Job arguments

  - `parent_id` — composed (parent) assessment point id to recalculate
  - `profile_id` — profile that triggered the change, used for audit logging
  """

  use Oban.Worker, queue: :assessments, max_attempts: 3

  alias Lanttern.AssessmentComposition
  alias Lanttern.Identity.Scope

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"parent_id" => parent_id} = args}) do
    scope = %Scope{profile_id: args["profile_id"]}

    AssessmentComposition.recalculate_all_composed_entries(scope, parent_id)
  end
end
