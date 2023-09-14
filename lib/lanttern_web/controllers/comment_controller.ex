defmodule LantternWeb.CommentController do
  use LantternWeb, :controller

  import LantternWeb.IdentityHelpers
  alias Lanttern.Conversation
  alias Lanttern.Conversation.Comment

  def index(conn, _params) do
    comments = Conversation.list_comments(preloads: [profile: [:teacher, :student]])
    render(conn, :index, comments: comments)
  end

  def new(conn, _params) do
    profile_options = generate_profile_options()
    changeset = Conversation.change_comment(%Comment{})
    render(conn, :new, profile_options: profile_options, changeset: changeset)
  end

  def create(conn, %{"comment" => comment_params}) do
    case Conversation.create_comment(comment_params) do
      {:ok, comment} ->
        conn
        |> put_flash(:info, "Comment created successfully.")
        |> redirect(to: ~p"/admin/comments/#{comment}")

      {:error, %Ecto.Changeset{} = changeset} ->
        profile_options = generate_profile_options()
        render(conn, :new, profile_options: profile_options, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    comment = Conversation.get_comment!(id, preloads: [profile: [:teacher, :student]])
    render(conn, :show, comment: comment)
  end

  def edit(conn, %{"id" => id}) do
    comment = Conversation.get_comment!(id)
    profile_options = generate_profile_options()
    changeset = Conversation.change_comment(comment)
    render(conn, :edit, comment: comment, profile_options: profile_options, changeset: changeset)
  end

  def update(conn, %{"id" => id, "comment" => comment_params}) do
    comment = Conversation.get_comment!(id)

    case Conversation.update_comment(comment, comment_params) do
      {:ok, comment} ->
        conn
        |> put_flash(:info, "Comment updated successfully.")
        |> redirect(to: ~p"/admin/comments/#{comment}")

      {:error, %Ecto.Changeset{} = changeset} ->
        profile_options = generate_profile_options()

        render(conn, :edit,
          comment: comment,
          profile_options: profile_options,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    comment = Conversation.get_comment!(id)
    {:ok, _comment} = Conversation.delete_comment(comment)

    conn
    |> put_flash(:info, "Comment deleted successfully.")
    |> redirect(to: ~p"/admin/comments")
  end
end
