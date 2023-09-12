defmodule LantternWeb.TeacherHTML do
  use LantternWeb, :html

  embed_templates "teacher_html/*"

  @doc """
  Renders a teacher form.
  """
  attr :school_options, :list, required: true
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def teacher_form(assigns)
end
