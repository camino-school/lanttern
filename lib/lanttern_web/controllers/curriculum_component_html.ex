defmodule LantternWeb.CurriculumComponentHTML do
  use LantternWeb, :html

  embed_templates "curriculum_component_html/*"

  @doc """
  Renders a curriculum_component form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :curriculum_options, :list, required: true
  attr :action, :string, required: true

  def curriculum_component_form(assigns)
end
