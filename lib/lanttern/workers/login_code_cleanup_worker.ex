defmodule Lanttern.Workers.LoginCodeCleanupWorker do
  @moduledoc """
  Oban worker that periodically cleans up expired login codes.

  This worker removes login codes that are both expired (older than 5 minutes)
  and past their rate limit window, ensuring the database doesn't accumulate
  unnecessary records while maintaining security through rate limiting.

  Runs automatically every hour via Oban's periodic jobs.
  """

  use Oban.Worker,
    queue: :cleanup,
    max_attempts: 3

  alias Lanttern.Identity

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Identity.cleanup_expired_login_codes()
    :ok
  end
end
