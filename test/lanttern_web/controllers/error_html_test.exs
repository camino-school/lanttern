defmodule LantternWeb.ErrorHTMLTest do
  use LantternWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(LantternWeb.ErrorHTML, "404", "html", []) =~ "Ooops, page not found"
  end

  test "renders 500.html" do
    assert render_to_string(LantternWeb.ErrorHTML, "500", "html", []) =~ "Internal server error"
  end
end
