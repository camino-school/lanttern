defmodule LantternWeb.SubjectController do
  use LantternWeb, :controller

  alias Lanttern.Taxonomy
  alias Lanttern.Taxonomy.Subject

  def index(conn, _params) do
    subjects = Taxonomy.list_subjects()
    render(conn, :index, subjects: subjects)
  end

  def new(conn, _params) do
    changeset = Taxonomy.change_subject(%Subject{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"subject" => subject_params}) do
    case Taxonomy.create_subject(subject_params) do
      {:ok, subject} ->
        conn
        |> put_flash(:info, "Subject created successfully.")
        |> redirect(to: ~p"/admin/taxonomy/subjects/#{subject}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    subject = Taxonomy.get_subject!(id)
    render(conn, :show, subject: subject)
  end

  def edit(conn, %{"id" => id}) do
    subject = Taxonomy.get_subject!(id)
    changeset = Taxonomy.change_subject(subject)
    render(conn, :edit, subject: subject, changeset: changeset)
  end

  def update(conn, %{"id" => id, "subject" => subject_params}) do
    subject = Taxonomy.get_subject!(id)

    case Taxonomy.update_subject(subject, subject_params) do
      {:ok, subject} ->
        conn
        |> put_flash(:info, "Subject updated successfully.")
        |> redirect(to: ~p"/admin/taxonomy/subjects/#{subject}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, subject: subject, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    subject = Taxonomy.get_subject!(id)
    {:ok, _subject} = Taxonomy.delete_subject(subject)

    conn
    |> put_flash(:info, "Subject deleted successfully.")
    |> redirect(to: ~p"/admin/taxonomy/subjects")
  end
end
