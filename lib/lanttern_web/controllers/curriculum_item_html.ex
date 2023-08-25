defmodule LantternWeb.CurriculumItemHTML do
  use LantternWeb, :html

  embed_templates "curriculum_item_html/*"

  @doc """
  Renders a curriculum item form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def curriculum_item_form(assigns)
end
