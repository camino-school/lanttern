defmodule LantternWeb.AdminControllerTest do
  use LantternWeb.ConnCase

  setup :register_and_log_in_root_admin

  describe "Seeds" do
    test "Seed base taxonomy", %{conn: conn} do
      conn = get(conn, ~p"/admin")
      assert html_response(conn, 200) =~ "Seed base taxonomy"

      conn = post(conn, ~p"/admin/seed_base_taxonomy")
      assert html_response(conn, 200) =~ "Base taxonomy seeded"
    end
  end
end
