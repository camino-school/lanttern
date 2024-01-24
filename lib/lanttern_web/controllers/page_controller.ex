defmodule LantternWeb.PageController do
  use LantternWeb, :controller

  def home(conn, _params) do
    google_client_id =
      Application.fetch_env!(:lanttern, LantternWeb.UserAuth)
      |> Keyword.get(:google_client_id)

    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home,
      layout: false,
      page_title: "Lanttern: visualizing learning patterns",
      google_client_id: google_client_id
    )
  end
end
