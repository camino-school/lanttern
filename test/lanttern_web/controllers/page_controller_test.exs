defmodule LantternWeb.PageControllerTest do
  use LantternWeb.ConnCase, async: true

  import PhoenixTest

  test "GET /", %{conn: conn} do
    conn
    |> visit(~p"/")
    |> assert_has("h1", text: "Lanttern")
    |> assert_has("strong", text: "visualize learning patterns")
  end
end
