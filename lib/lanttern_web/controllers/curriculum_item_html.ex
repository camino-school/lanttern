defmodule LantternWeb.CurriculumItemHTML do
  use LantternWeb, :html

  embed_templates "curriculum_item_html/*"

  @doc """
  Renders a curriculum item form.
  """
  attr :curriculum_component_options, :list, required: true
  attr :subject_options, :list, required: true
  attr :year_options, :list, required: true
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def curriculum_item_form(assigns)
end
