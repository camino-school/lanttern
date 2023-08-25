defmodule LantternWeb.CurriculumRelationshipHTML do
  use LantternWeb, :html

  embed_templates "curriculum_relationship_html/*"

  @doc """
  Renders a curriculum_relationship form.
  """
  attr :curriculum_item_options, :list, required: true
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def curriculum_relationship_form(assigns)
end
