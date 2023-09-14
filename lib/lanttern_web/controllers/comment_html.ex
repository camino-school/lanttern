defmodule LantternWeb.CommentHTML do
  use LantternWeb, :html

  embed_templates "comment_html/*"

  @doc """
  Renders a comment form.
  """
  attr :profile_options, :list, required: true
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def comment_form(assigns)

  def comment_author(%{profile: %{type: "teacher", teacher: teacher}}),
    do: "Teacher #{teacher.name}"

  def comment_author(%{profile: %{type: "student", student: student}}),
    do: "Student #{student.name}"

  def comment_author(_comment), do: "Invalid author"
end
