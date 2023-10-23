defmodule LantternWeb.AdminController do
  use LantternWeb, :controller

  alias Lanttern.Taxonomy
  alias Lanttern.BNCC

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

  def seed_bncc(conn, _params) do
    case BNCC.seed_bncc() do
      {:ok, _} ->
        conn =
          conn
          |> put_flash(:info, "BNCC registered!")

        render(conn, :home, generate_assigns())

      {:error, error} ->
        conn =
          conn
          |> put_flash(:error, error)

        render(conn, :home, generate_assigns())
    end
  end

  defp generate_assigns() do
    [
      has_base_taxonomy: Taxonomy.has_base_taxonomy?(),
      is_bncc_registered: BNCC.is_bncc_registered?()
    ]
  end
end
