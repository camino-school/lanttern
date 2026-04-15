defmodule LantternWeb.AdminController do
  use LantternWeb, :controller

  alias Lanttern.Taxonomy

  def home(conn, _params) do
    render(conn, :home, generate_assigns())
  end

  def seed_base_taxonomy(conn, _params) do
    Taxonomy.seed_base_taxonomy()

    conn =
      conn
      |> put_flash(:info, "Base taxonomy created!")

    render(conn, :home, generate_assigns())
  end

  defp generate_assigns do
    [
      has_base_taxonomy: Taxonomy.has_base_taxonomy?()
    ]
  end
end
