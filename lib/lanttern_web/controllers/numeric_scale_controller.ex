defmodule LantternWeb.NumericScaleController do
  use LantternWeb, :controller

  alias Lanttern.Grading
  alias Lanttern.Grading.NumericScale

  def index(conn, _params) do
    numeric_scales = Grading.list_numeric_scales()
    render(conn, :index, numeric_scales: numeric_scales)
  end

  def new(conn, _params) do
    changeset = Grading.change_numeric_scale(%NumericScale{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"numeric_scale" => numeric_scale_params}) do
    case Grading.create_numeric_scale(numeric_scale_params) do
      {:ok, numeric_scale} ->
        conn
        |> put_flash(:info, "Numeric scale created successfully.")
        |> redirect(to: ~p"/grading/numeric_scales/#{numeric_scale}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    numeric_scale = Grading.get_numeric_scale!(id)
    render(conn, :show, numeric_scale: numeric_scale)
  end

  def edit(conn, %{"id" => id}) do
    numeric_scale = Grading.get_numeric_scale!(id)
    changeset = Grading.change_numeric_scale(numeric_scale)
    render(conn, :edit, numeric_scale: numeric_scale, changeset: changeset)
  end

  def update(conn, %{"id" => id, "numeric_scale" => numeric_scale_params}) do
    numeric_scale = Grading.get_numeric_scale!(id)

    case Grading.update_numeric_scale(numeric_scale, numeric_scale_params) do
      {:ok, numeric_scale} ->
        conn
        |> put_flash(:info, "Numeric scale updated successfully.")
        |> redirect(to: ~p"/grading/numeric_scales/#{numeric_scale}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, numeric_scale: numeric_scale, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    numeric_scale = Grading.get_numeric_scale!(id)
    {:ok, _numeric_scale} = Grading.delete_numeric_scale(numeric_scale)

    conn
    |> put_flash(:info, "Numeric scale deleted successfully.")
    |> redirect(to: ~p"/grading/numeric_scales")
  end
end
