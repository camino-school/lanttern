defmodule Lanttern.Engagement do
  @moduledoc """
  Server-side engagement metrics tracking.

  Provides functions to track daily active profiles, strand report views,
  and strand report lesson views. Operates asynchronously in prod/dev
  and synchronously in tests (mirrors `Lanttern.AuditLog` pattern).
  """

  require Logger

  alias Lanttern.Engagement.DailyActiveProfile
  alias Lanttern.Engagement.StrandReportLessonView
  alias Lanttern.Engagement.StrandReportView
  alias Lanttern.Identity.Scope
  alias Lanttern.Repo

  @doc """
  Tracks a daily active profile entry for the given scope.

  Deduplicates per profile per day via unique constraint (on_conflict: :nothing).
  """
  @spec track_dau(Scope.t() | any()) :: :ok
  def track_dau(%Scope{profile_id: pid}) when not is_nil(pid) do
    attrs = %{profile_id: pid, date: Date.utc_today()}

    %DailyActiveProfile{}
    |> DailyActiveProfile.changeset(attrs)
    |> do_insert(conflict_target: [:profile_id, :date])
  end

  def track_dau(_scope), do: :ok

  @doc """
  Tracks a strand report tab view for the given scope.

  Deduplicates per profile per strand report per tab per day.
  """
  @spec track_strand_report_view(
          Scope.t() | any(),
          pos_integer(),
          pos_integer() | nil,
          String.t(),
          String.t()
        ) :: :ok
  def track_strand_report_view(
        %Scope{profile_id: pid},
        strand_report_id,
        student_report_card_id,
        navigation_context,
        tab
      )
      when not is_nil(pid) do
    attrs = %{
      profile_id: pid,
      strand_report_id: strand_report_id,
      student_report_card_id: student_report_card_id,
      navigation_context: navigation_context,
      tab: tab,
      date: Date.utc_today()
    }

    %StrandReportView{}
    |> StrandReportView.changeset(attrs)
    |> do_insert(conflict_target: [:profile_id, :strand_report_id, :tab, :date])
  end

  def track_strand_report_view(
        _scope,
        _strand_report_id,
        _student_report_card_id,
        _navigation_context,
        _tab
      ),
      do: :ok

  @doc """
  Tracks a strand report lesson view for the given scope.

  Deduplicates per profile per lesson per day.
  """
  @spec track_strand_report_lesson_view(
          Scope.t() | any(),
          pos_integer(),
          pos_integer(),
          pos_integer() | nil
        ) :: :ok
  def track_strand_report_lesson_view(
        %Scope{profile_id: pid},
        strand_report_id,
        lesson_id,
        student_report_card_id
      )
      when not is_nil(pid) do
    attrs = %{
      profile_id: pid,
      strand_report_id: strand_report_id,
      lesson_id: lesson_id,
      student_report_card_id: student_report_card_id,
      date: Date.utc_today()
    }

    %StrandReportLessonView{}
    |> StrandReportLessonView.changeset(attrs)
    |> do_insert(conflict_target: [:profile_id, :lesson_id, :date])
  end

  def track_strand_report_lesson_view(
        _scope,
        _strand_report_id,
        _lesson_id,
        _student_report_card_id
      ),
      do: :ok

  defp do_insert(changeset, conflict_opts) do
    insert_opts = [on_conflict: :nothing, conflict_target: conflict_opts[:conflict_target]]

    case mode() do
      :sync ->
        insert_record(changeset, insert_opts)

      :async ->
        Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
          insert_record(changeset, insert_opts)
        end)
    end

    :ok
  end

  defp insert_record(changeset, opts) do
    case Repo.insert(changeset, opts) do
      {:ok, _record} ->
        :ok

      {:error, changeset} ->
        Logger.warning("Failed to insert engagement metric: #{inspect(changeset.errors)}")
        :error
    end
  end

  defp mode do
    Application.get_env(:lanttern, __MODULE__, [])[:mode] || :async
  end
end
