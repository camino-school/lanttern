defmodule LantternWeb.OrdinalScaleController do
  use LantternWeb, :controller

  alias Lanttern.Grading
  alias Lanttern.Grading.OrdinalScale

  def index(conn, _params) do
    ordinal_scales = Grading.list_ordinal_scales()
    render(conn, :index, ordinal_scales: ordinal_scales)
  end

  def new(conn, _params) do
    changeset = Grading.change_ordinal_scale(%OrdinalScale{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"ordinal_scale" => ordinal_scale_params}) do
    case Grading.create_ordinal_scale(ordinal_scale_params) do
      {:ok, ordinal_scale} ->
        conn
        |> put_flash(:info, "Ordinal scale created successfully.")
        |> redirect(to: ~p"/grading/ordinal_scales/#{ordinal_scale}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    ordinal_scale = Grading.get_ordinal_scale!(id)
    render(conn, :show, ordinal_scale: ordinal_scale)
  end

  def edit(conn, %{"id" => id}) do
    ordinal_scale = Grading.get_ordinal_scale!(id)
    changeset = Grading.change_ordinal_scale(ordinal_scale)
    render(conn, :edit, ordinal_scale: ordinal_scale, changeset: changeset)
  end

  def update(conn, %{"id" => id, "ordinal_scale" => ordinal_scale_params}) do
    ordinal_scale = Grading.get_ordinal_scale!(id)

    case Grading.update_ordinal_scale(ordinal_scale, ordinal_scale_params) do
      {:ok, ordinal_scale} ->
        conn
        |> put_flash(:info, "Ordinal scale updated successfully.")
        |> redirect(to: ~p"/grading/ordinal_scales/#{ordinal_scale}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, ordinal_scale: ordinal_scale, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    ordinal_scale = Grading.get_ordinal_scale!(id)
    {:ok, _ordinal_scale} = Grading.delete_ordinal_scale(ordinal_scale)

    conn
    |> put_flash(:info, "Ordinal scale deleted successfully.")
    |> redirect(to: ~p"/grading/ordinal_scales")
  end
end
