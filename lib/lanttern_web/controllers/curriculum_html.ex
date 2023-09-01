defmodule LantternWeb.CurriculumHTML do
  use LantternWeb, :html

  embed_templates "curriculum_html/*"

  @doc """
  Renders a curriculum form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def curriculum_form(assigns)
end
