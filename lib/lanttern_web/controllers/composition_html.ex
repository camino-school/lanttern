defmodule LantternWeb.CompositionHTML do
  use LantternWeb, :html

  embed_templates "composition_html/*"

  @doc """
  Renders a composition form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :scale_options, :list, required: true

  def composition_form(assigns)
end
