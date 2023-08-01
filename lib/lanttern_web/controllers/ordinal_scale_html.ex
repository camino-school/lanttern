defmodule LantternWeb.OrdinalScaleHTML do
  use LantternWeb, :html

  embed_templates "ordinal_scale_html/*"

  @doc """
  Renders a ordinal_scale form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def ordinal_scale_form(assigns)
end
