defmodule LantternWeb.OrdinalValueController do
  use LantternWeb, :controller

  alias Lanttern.Grading
  alias Lanttern.Grading.OrdinalValue

  def index(conn, _params) do
    ordinal_values = Grading.list_ordinal_values(:scale)
    render(conn, :index, ordinal_values: ordinal_values)
  end

  def new(conn, _params) do
    options = generate_scale_options()
    changeset = Grading.change_ordinal_value(%OrdinalValue{})
    render(conn, :new, scale_options: options, changeset: changeset)
  end

  def create(conn, %{"ordinal_value" => ordinal_value_params}) do
    case Grading.create_ordinal_value(ordinal_value_params) do
      {:ok, ordinal_value} ->
        conn
        |> put_flash(:info, "Ordinal value created successfully.")
        |> redirect(to: ~p"/grading/ordinal_values/#{ordinal_value}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_scale_options()
        render(conn, :new, scale_options: options, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    ordinal_value = Grading.get_ordinal_value!(id, :scale)
    render(conn, :show, ordinal_value: ordinal_value)
  end

  def edit(conn, %{"id" => id}) do
    ordinal_value = Grading.get_ordinal_value!(id)
    options = generate_scale_options()
    changeset = Grading.change_ordinal_value(ordinal_value)

    render(conn, :edit,
      ordinal_value: ordinal_value,
      scale_options: options,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "ordinal_value" => ordinal_value_params}) do
    ordinal_value = Grading.get_ordinal_value!(id)

    case Grading.update_ordinal_value(ordinal_value, ordinal_value_params) do
      {:ok, ordinal_value} ->
        conn
        |> put_flash(:info, "Ordinal value updated successfully.")
        |> redirect(to: ~p"/grading/ordinal_values/#{ordinal_value}")

      {:error, %Ecto.Changeset{} = changeset} ->
        options = generate_scale_options()

        render(conn, :edit,
          ordinal_value: ordinal_value,
          scale_options: options,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    ordinal_value = Grading.get_ordinal_value!(id)
    {:ok, _ordinal_value} = Grading.delete_ordinal_value(ordinal_value)

    conn
    |> put_flash(:info, "Ordinal value deleted successfully.")
    |> redirect(to: ~p"/grading/ordinal_values")
  end

  defp generate_scale_options() do
    Grading.list_ordinal_scales()
    |> Enum.map(fn s -> ["#{s.name}": s.id] end)
    |> Enum.concat()
  end
end
