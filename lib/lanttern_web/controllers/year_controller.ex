defmodule LantternWeb.YearController do
  use LantternWeb, :controller

  alias Lanttern.Taxonomy
  alias Lanttern.Taxonomy.Year

  def index(conn, _params) do
    years = Taxonomy.list_years()
    render(conn, :index, years: years)
  end

  def new(conn, _params) do
    changeset = Taxonomy.change_year(%Year{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"year" => year_params}) do
    case Taxonomy.create_year(year_params) do
      {:ok, year} ->
        conn
        |> put_flash(:info, "Year created successfully.")
        |> redirect(to: ~p"/admin/years/#{year}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    year = Taxonomy.get_year!(id)
    render(conn, :show, year: year)
  end

  def edit(conn, %{"id" => id}) do
    year = Taxonomy.get_year!(id)
    changeset = Taxonomy.change_year(year)
    render(conn, :edit, year: year, changeset: changeset)
  end

  def update(conn, %{"id" => id, "year" => year_params}) do
    year = Taxonomy.get_year!(id)

    case Taxonomy.update_year(year, year_params) do
      {:ok, year} ->
        conn
        |> put_flash(:info, "Year updated successfully.")
        |> redirect(to: ~p"/admin/years/#{year}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, year: year, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    year = Taxonomy.get_year!(id)
    {:ok, _year} = Taxonomy.delete_year(year)

    conn
    |> put_flash(:info, "Year deleted successfully.")
    |> redirect(to: ~p"/admin/years")
  end
end
