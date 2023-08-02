defmodule LantternWeb.CompositionComponentHTML do
  use LantternWeb, :html

  embed_templates "composition_component_html/*"

  @doc """
  Renders a composition_component form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :composition_options, :list, required: true

  def composition_component_form(assigns)
end
