defmodule LantternWeb.CompositionComponentItemHTML do
  use LantternWeb, :html

  embed_templates "composition_component_item_html/*"

  @doc """
  Renders a composition_component_item form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def composition_component_item_form(assigns)
end
