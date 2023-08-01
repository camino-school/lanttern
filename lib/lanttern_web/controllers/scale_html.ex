defmodule LantternWeb.ScaleHTML do
  use LantternWeb, :html

  embed_templates "scale_html/*"

  @doc """
  Renders a scale form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def scale_form(assigns)
end
