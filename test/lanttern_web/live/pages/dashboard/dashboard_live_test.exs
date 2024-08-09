defmodule LantternWeb.DashboardLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.PersonalizationFixtures
  alias Lanttern.SchoolsFixtures
  alias Lanttern.TaxonomyFixtures

  @live_view_path "/dashboard"
  @form_selector "#assessment-points-filter-view-form"

  setup :register_and_log_in_teacher

  describe "Dashboard live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Dashboard 🚧\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end
  end

  describe "Dashboard filter views" do
    setup :create_profile_filter_view

    test "list filter views", %{
      conn: conn,
      filter_view: filter_view,
      filter_subject: subject,
      filter_class: class
    } do
      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("a", filter_view.name)
      assert view |> has_element?("span", subject.name)
      assert view |> has_element?("span", class.name)
    end

    @tag :skip
    test "navigate using filter view", %{
      conn: conn,
      filter_view: filter_view,
      filter_subject: subject,
      filter_class: class
    } do
      {:ok, view, _html} = live(conn, @live_view_path)

      view
      |> element("a", filter_view.name)
      |> render_click()

      {path, _flash} = assert_redirect(view)

      # the order of URL params are not guaranteed. test each param separately
      # expected format: "/assessment_points?subjects_ids[]=1&classes_ids[]=1"
      assert path =~ "/assessment_points?"
      assert path =~ "subjects_ids[]=#{subject.id}"
      assert path =~ "classes_ids[]=#{class.id}"
    end

    test "create filter view", %{conn: conn, user: %{current_profile: profile}} do
      create_subject = TaxonomyFixtures.subject_fixture()
      create_class = SchoolsFixtures.class_fixture()

      {:ok, view, _html} = live(conn, @live_view_path)

      # open create modal
      view
      |> element("a", "Create new view")
      |> render_click()

      # submit form
      view
      |> element(@form_selector)
      |> render_submit(%{
        "profile_view" => %{
          "name" => "Create filter view XYZ",
          "profile_id" => profile.id,
          "subjects_ids" => [create_subject.id],
          "classes_ids" => [create_class.id]
        }
      })

      # assert new view display in dashboard
      assert render(view) =~ "Create filter view XYZ"
    end

    test "delete filter view", %{conn: conn, filter_view: filter_view} do
      {:ok, view, _html} = live(conn, @live_view_path)

      # "click" remove
      view
      |> element("button#remove-filter-view-filter_views-#{filter_view.id}")
      |> render_click()

      # assert view is removed
      refute view |> has_element?("a", filter_view.name)
    end
  end

  # setup

  defp create_profile_filter_view(%{user: %{current_profile: profile}}) do
    subject = TaxonomyFixtures.subject_fixture(%{name: "subject for filter view"})
    class = SchoolsFixtures.class_fixture(%{name: "class for filter view"})

    filter_view =
      PersonalizationFixtures.profile_view_fixture(%{
        name: "Filter view in dashboard",
        subjects_ids: [subject.id],
        classes_ids: [class.id],
        profile_id: profile.id
      })

    %{
      filter_view: filter_view,
      filter_subject: subject,
      filter_class: class
    }
  end
end
