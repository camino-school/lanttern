defmodule LantternWeb.Assessments.EntryDetailsOverlayComponentSyncTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Repo

  setup :register_and_log_in_staff_member

  # Minimal host LiveView so we can drive the (stateful) overlay live_component
  # through real events/async — the production grid wires it up the same way.
  defmodule HostLive do
    use Phoenix.LiveView

    alias LantternWeb.Assessments.EntryDetailsOverlayComponent

    @impl true
    def mount(_params, session, socket) do
      %{"current_user" => current_user, "entry" => entry} = session
      {:ok, assign(socket, current_user: current_user, entry: entry)}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div>
        <.live_component
          module={EntryDetailsOverlayComponent}
          id="entry-overlay"
          entry={@entry}
          current_user={@current_user}
          on_cancel={%Phoenix.LiveView.JS{}}
        />
      </div>
      """
    end
  end

  describe "sync composed entry on \"View composition\"" do
    setup %{user: user} do
      school = Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      strand = insert(:strand)
      numeric_scale = insert(:scale, school: school, type: "numeric", max_score: 100.0)

      parent_ap =
        insert(:assessment_point,
          strand_id: strand.id,
          scale: numeric_scale,
          uses_composition: true
        )

      child_1 = insert(:assessment_point, strand_id: strand.id, scale: numeric_scale)
      child_2 = insert(:assessment_point, strand_id: strand.id, scale: numeric_scale)

      insert(:assessment_point_component, parent: parent_ap, component: child_1, weight: 1.0)
      insert(:assessment_point_component, parent: parent_ap, component: child_2, weight: 1.0)

      student = insert(:student, school: school)

      # components sum to 30 + 8 = 38
      insert(:assessment_point_entry,
        assessment_point: child_1,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 30.0
      )

      insert(:assessment_point_entry,
        assessment_point: child_2,
        student: student,
        scale: numeric_scale,
        scale_type: "numeric",
        score: 8.0
      )

      %{parent_ap: parent_ap, student: student, numeric_scale: numeric_scale}
    end

    test "recomputes a stale composed entry to match its components", %{
      conn: conn,
      user: user,
      parent_ap: parent_ap,
      student: student,
      numeric_scale: numeric_scale
    } do
      # stale: stored 99.0 while the components actually sum to 38.0
      parent_entry =
        insert(:assessment_point_entry,
          assessment_point: parent_ap,
          student: student,
          scale: numeric_scale,
          scale_type: "numeric",
          score: 99.0,
          use_manual_input: false
        )

      {:ok, view, _html} =
        live_isolated(conn, HostLive, session: %{"current_user" => user, "entry" => parent_entry})

      view
      |> element("button", "View composition")
      |> render_click()

      render_async(view)

      assert %AssessmentPointEntry{score: 38.0} =
               Repo.get!(AssessmentPointEntry, parent_entry.id)
    end

    test "leaves an in-sync composed entry untouched", %{
      conn: conn,
      user: user,
      parent_ap: parent_ap,
      student: student,
      numeric_scale: numeric_scale
    } do
      parent_entry =
        insert(:assessment_point_entry,
          assessment_point: parent_ap,
          student: student,
          scale: numeric_scale,
          scale_type: "numeric",
          score: 38.0,
          use_manual_input: false
        )

      {:ok, view, _html} =
        live_isolated(conn, HostLive, session: %{"current_user" => user, "entry" => parent_entry})

      view
      |> element("button", "View composition")
      |> render_click()

      render_async(view)

      reloaded = Repo.get!(AssessmentPointEntry, parent_entry.id)
      assert reloaded.score == 38.0
      # idempotent recalc is a no-op → no write → updated_at unchanged
      assert reloaded.updated_at == parent_entry.updated_at
    end

    test "does not touch a manual-input entry (button is unavailable)", %{
      conn: conn,
      user: user,
      parent_ap: parent_ap,
      student: student,
      numeric_scale: numeric_scale
    } do
      parent_entry =
        insert(:assessment_point_entry,
          assessment_point: parent_ap,
          student: student,
          scale: numeric_scale,
          scale_type: "numeric",
          score: 99.0,
          use_manual_input: true
        )

      {:ok, view, _html} =
        live_isolated(conn, HostLive, session: %{"current_user" => user, "entry" => parent_entry})

      # with manual input on, the entry is not composed → no "View composition"
      refute has_element?(view, "button", "View composition")
      assert Repo.get!(AssessmentPointEntry, parent_entry.id).score == 99.0
    end
  end
end
