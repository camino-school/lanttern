defmodule LantternWeb.StrandLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.LearningContextFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_staff_member]

  describe "Strand details live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture(%{name: "strand abc"})
      conn = get(conn, "#{@live_view_base_path}/#{strand.id}")

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*strand abc\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "display strand basic info", %{conn: conn} do
      subject = TaxonomyFixtures.subject_fixture(%{name: "subject abc"})
      year = TaxonomyFixtures.year_fixture(%{name: "year abc"})

      strand =
        LearningContextFixtures.strand_fixture(%{
          name: "strand abc",
          subjects_ids: [subject.id],
          years_ids: [year.id]
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}")

      assert view |> has_element?("h1", strand.name)
      assert view |> has_element?("span", subject.name)
      assert view |> has_element?("span", year.name)
    end

    test "strand tab navigation", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture(%{description: "strand description abc"})

      _moment =
        LearningContextFixtures.moment_fixture(%{name: "moment abc", strand_id: strand.id})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}")

      assert view |> has_element?("p", "strand description abc")
      assert view |> has_element?("button", "moment abc")

      # assessment tab

      view
      |> element("#strand-nav-tabs a", "Assessment")
      |> render_click()

      assert_patch(view)

      # back to lessons tab

      view
      |> element("#strand-nav-tabs a", "Lessons")
      |> render_click()

      assert_patch(view)

      assert view |> has_element?("p", "strand description abc")
    end
  end

  describe "AI button visibility" do
    test "Plan with AI button is not visible without agents_management permission", %{conn: conn} do
      strand = insert(:strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> refute_has("a", text: "Plan with AI")
    end

    test "Plan with AI button is visible with agents_management permission", context do
      %{conn: conn} = set_user_permissions(["agents_management"], context)
      strand = insert(:strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> assert_has("a", text: "Plan with AI")
    end
  end

  describe "Strand management" do
    test "edit strand", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture(%{name: "strand abc"})
      subject = TaxonomyFixtures.subject_fixture(%{name: "subject abc"})
      year = TaxonomyFixtures.year_fixture(%{name: "year abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}?is_editing=true")

      assert view
             |> has_element?("h2", "Edit strand")

      # add subject
      view
      |> element("#strand-form #strand_subject_id")
      |> render_change(%{"strand" => %{"subject_id" => subject.id}})

      # add year
      view
      |> element("#strand-form #strand_year_id")
      |> render_change(%{"strand" => %{"year_id" => year.id}})

      # submit form with valid field
      view
      |> element("#strand-form")
      |> render_submit(%{
        "strand" => %{
          "name" => "strand name xyz"
        }
      })

      assert_patch(view, "#{@live_view_base_path}/#{strand.id}")

      assert view |> has_element?("h1", "strand name xyz")
      assert view |> has_element?("span", subject.name)
      assert view |> has_element?("span", year.name)
    end

    test "delete strand", %{conn: conn} do
      strand = LearningContextFixtures.strand_fixture()

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}")

      view
      |> element("button#remove-strand-#{strand.id}")
      |> render_click()

      assert_redirect(view, "/strands")
    end
  end

  describe "strand lock" do
    test "lock control is hidden without strand_lock_management permission", %{conn: conn} do
      strand = insert(:strand, is_locked: false)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> refute_has("#toggle-lock-strand-#{strand.id}")
    end

    test "lock control is shown for a holder and reads 'Lock strand' when unlocked", context do
      %{conn: conn} = set_user_permissions(["strand_lock_management"], context)
      strand = insert(:strand, is_locked: false)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> assert_has("#toggle-lock-strand-#{strand.id}", text: "Lock strand")
    end

    test "lock control reads 'Unlock strand' for a holder when the strand is locked", context do
      %{conn: conn} = set_user_permissions(["strand_lock_management"], context)
      strand = insert(:strand, is_locked: true)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> assert_has("#toggle-lock-strand-#{strand.id}", text: "Unlock strand")
    end

    test "a holder can lock a strand, persisting the lock and showing the indicator", context do
      %{conn: conn} = set_user_permissions(["strand_lock_management"], context)
      strand = insert(:strand, is_locked: false)

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}")

      refute view |> has_element?("p", "This strand is locked")

      view
      |> element("#toggle-lock-strand-#{strand.id}")
      |> render_click()

      assert view |> has_element?("p", "This strand is locked")
      assert %{is_locked: true} = Lanttern.Repo.get!(Lanttern.LearningContext.Strand, strand.id)
    end

    test "a holder can unlock a locked strand", context do
      %{conn: conn} = set_user_permissions(["strand_lock_management"], context)
      strand = insert(:strand, is_locked: true)

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}")

      view
      |> element("#toggle-lock-strand-#{strand.id}")
      |> render_click()

      refute view |> has_element?("p", "This strand is locked")
      assert %{is_locked: false} = Lanttern.Repo.get!(Lanttern.LearningContext.Strand, strand.id)
    end

    test "the lock indicator shows provenance to everyone when the strand is locked", %{
      conn: conn
    } do
      staff_member = insert(:staff_member, name: "Coordinator Jane")

      strand =
        insert(:strand,
          is_locked: true,
          locked_at: ~U[2026-06-01 10:00:00Z],
          locked_by_staff_member: staff_member
        )

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> assert_has("p", text: "This strand is locked")
      |> assert_has("p", text: "Locked by Coordinator Jane")
    end

    test "the lock indicator is hidden when the strand is unlocked", %{conn: conn} do
      strand = insert(:strand, is_locked: false)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> refute_has("p", text: "This strand is locked")
    end
  end
end
