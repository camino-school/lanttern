defmodule LantternWeb.ILPSettingsLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.Repo

  alias Lanttern.ILP
  alias Lanttern.ILPFixtures

  @live_view_path "/ilp/settings/"

  setup [:register_and_log_in_staff_member]

  describe "ILP settings live view basic navigation" do
    test "school manager disconnected and connected mount", context do
      %{conn: conn} = set_user_permissions(["school_management"], context)
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Settings\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "list templates", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)

      school_id = user.current_profile.school_id

      template =
        ILPFixtures.ilp_template_fixture(%{school_id: school_id, name: "ilp template abc"})
        |> Repo.preload(sections: :components)

      params =
        %{
          "sections" => %{
            "0" => %{
              "name" => "ilp section abc",
              "components" => %{
                "0" => %{"name" => "ilp component abc", "template_id" => template.id}
              }
            }
          }
        }

      ILP.update_ilp_template(template, params)

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h3", "ilp template abc")
      assert view |> has_element?("div", "ilp section abc")
      assert view |> has_element?("div", "ilp component abc")
    end
  end

  describe "ILP settings live view access" do
    test "user without school management can't access settings page", %{conn: conn} do
      {:error,
       {:live_redirect,
        %{to: "/ilp", flash: %{"error" => "You don't have access to ILP settings page"}}}} =
        live(conn, @live_view_path)
    end

    test "user without full access can access only its own records, records shared with school, or records assigned to them",
         context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)

      school_id = user.current_profile.school_id

      ILPFixtures.ilp_template_fixture(%{school_id: school_id, name: "ilp template abc"})
      ILPFixtures.ilp_template_fixture(%{name: "other school template"})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h3", "ilp template abc")
      refute view |> has_element?("h3", "other school template")
    end
  end
end
