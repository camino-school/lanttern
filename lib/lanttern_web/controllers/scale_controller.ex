defmodule LantternWeb.ScaleController do
  use LantternWeb, :controller

  alias Lanttern.Grading
  alias Lanttern.Grading.Scale

  def index(conn, _params) do
    scales = Grading.list_scales()
    render(conn, :index, scales: scales)
  end

  def new(conn, _params) do
    changeset = Grading.change_scale(%Scale{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"scale" => scale_params}) do
    case Grading.create_scale(scale_params) do
      {:ok, scale} ->
        conn
        |> put_flash(:info, "Scale created successfully.")
        |> redirect(to: ~p"/admin/scales/#{scale}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    scale = Grading.get_scale!(id)
    render(conn, :show, scale: scale)
  end

  def edit(conn, %{"id" => id}) do
    scale = Grading.get_scale!(id)
    changeset = Grading.change_scale(scale)
    render(conn, :edit, scale: scale, changeset: changeset)
  end

  def update(conn, %{"id" => id, "scale" => scale_params}) do
    scale = Grading.get_scale!(id)

    case Grading.update_scale(scale, scale_params) do
      {:ok, scale} ->
        conn
        |> put_flash(:info, "Scale updated successfully.")
        |> redirect(to: ~p"/admin/scales/#{scale}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, scale: scale, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    scale = Grading.get_scale!(id)
    {:ok, _scale} = Grading.delete_scale(scale)

    conn
    |> put_flash(:info, "Scale deleted successfully.")
    |> redirect(to: ~p"/admin/scales")
  end
end
