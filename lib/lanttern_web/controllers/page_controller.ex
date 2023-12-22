defmodule LantternWeb.PageController do
  use LantternWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false, page_title: "Lanttern: visualizing learning patterns")
  end
end
