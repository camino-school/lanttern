defmodule Lanttern.Workers.LoginCodeCleanupWorkerTest do
  use Lanttern.DataCase, async: true
  use Oban.Testing, repo: Lanttern.Repo

  import Ecto.Changeset

  alias Lanttern.Identity.LoginCode
  alias Lanttern.Workers.LoginCodeCleanupWorker

  describe "perform/1" do
    test "successfully cleans up expired login codes" do
      # Create test data: expired codes that are past rate limit
      old_time = NaiveDateTime.utc_now(:second) |> NaiveDateTime.add(-10, :minute)
      old_rate_limit = DateTime.utc_now(:second) |> DateTime.add(-5, :minute)

      codes_to_cleanup =
        for i <- 1..2 do
          {_plain_code, hashed_code} = LoginCode.generate_code()
          code = LoginCode.build("cleanup#{i}@example.com", hashed_code)
          {:ok, code} = Repo.insert(code)

          Repo.update!(
            Ecto.Changeset.change(code,
              inserted_at: old_time,
              rate_limited_until: old_rate_limit
            )
          )

          code
        end

      # Create a fresh code that should not be cleaned up
      {_plain_code, hashed_code} = LoginCode.generate_code()
      fresh_code = LoginCode.build("fresh@example.com", hashed_code)
      {:ok, fresh_code} = Repo.insert(fresh_code)

      # Perform job
      assert :ok = perform_job(LoginCodeCleanupWorker, %{})

      # Verify cleanup happened
      for code <- codes_to_cleanup do
        refute Repo.get(LoginCode, code.id)
      end

      # Verify fresh code remains
      assert Repo.get(LoginCode, fresh_code.id)
    end

    test "succeeds when no codes need cleanup" do
      # Create only fresh codes
      {_plain_code, hashed_code} = LoginCode.generate_code()
      fresh_code = LoginCode.build("fresh@example.com", hashed_code)
      {:ok, _fresh_code} = Repo.insert(fresh_code)

      # Perform job
      assert :ok = perform_job(LoginCodeCleanupWorker, %{})

      # Verify fresh code still exists
      assert Repo.get_by(LoginCode, email: "fresh@example.com")
    end

    test "succeeds when no login codes exist" do
      # Empty database
      assert Repo.aggregate(LoginCode, :count, :id) == 0

      # Perform job
      assert :ok = perform_job(LoginCodeCleanupWorker, %{})

      # Should complete without error
      assert Repo.aggregate(LoginCode, :count, :id) == 0
    end

    test "handles large number of expired codes efficiently" do
      # Create many expired codes
      old_time = NaiveDateTime.utc_now(:second) |> NaiveDateTime.add(-10, :minute)
      old_rate_limit = DateTime.utc_now(:second) |> DateTime.add(-5, :minute)

      _codes =
        for i <- 1..100 do
          {_plain_code, hashed_code} = LoginCode.generate_code()
          code = LoginCode.build("cleanup#{i}@example.com", hashed_code)
          {:ok, code} = Repo.insert(code)

          Repo.update!(
            Ecto.Changeset.change(code,
              inserted_at: old_time,
              rate_limited_until: old_rate_limit
            )
          )

          code
        end

      initial_count = Repo.aggregate(LoginCode, :count, :id)
      assert initial_count == 100

      # Perform cleanup
      assert :ok = perform_job(LoginCodeCleanupWorker, %{})

      # Verify all were cleaned up
      final_count = Repo.aggregate(LoginCode, :count, :id)
      assert final_count == 0
    end
  end

  describe "integration with Oban" do
    test "job is properly configured" do
      job = LoginCodeCleanupWorker.new(%{})

      assert get_change(job, :worker) == "Lanttern.Workers.LoginCodeCleanupWorker"
      assert get_change(job, :queue) == "cleanup"
      assert get_change(job, :max_attempts) == 3
    end

    test "job can be enqueued and performed" do
      # Enqueue the job
      assert {:ok, _job} = LoginCodeCleanupWorker.new(%{}) |> Oban.insert()

      # Perform the job
      assert_enqueued(worker: LoginCodeCleanupWorker, queue: "cleanup")
      assert :ok = perform_job(LoginCodeCleanupWorker, %{})
    end
  end
end
