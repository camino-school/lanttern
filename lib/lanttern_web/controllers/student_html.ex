defmodule LantternWeb.StudentHTML do
  use LantternWeb, :html

  embed_templates "student_html/*"

  @doc """
  Renders a student form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :class_options, :list, required: true

  def student_form(assigns)
end
