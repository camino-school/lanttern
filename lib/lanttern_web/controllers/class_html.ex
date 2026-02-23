defmodule LantternWeb.ClassHTML do
  use LantternWeb, :html

  embed_templates "class_html/*"

  @doc """
  Renders a class form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :school_options, :list, required: true
  attr :year_options, :list, required: true
  attr :cycle_options, :list, required: true
  attr :student_options, :list, required: true
  attr :staff_member_options, :list, required: true

  def class_form(assigns)
end
