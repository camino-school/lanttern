defmodule LantternWeb.AdminController do
  use LantternWeb, :controller

  alias Lanttern.Seeds

  def home(conn, _params) do
    has_base_taxonomy = Seeds.check_base_taxonomy()

    render(conn, :home, has_base_taxonomy: has_base_taxonomy)
  end

  def seed_base_taxonomy(conn, _params) do
    Seeds.seed_base_taxonomy()

    conn =
      conn
      |> put_flash(:info, "Base taxonomy created!")

    render(conn, :home, has_base_taxonomy: true)
  end
end
