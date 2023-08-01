defmodule LantternWeb.NumericScaleHTML do
  use LantternWeb, :html

  embed_templates "numeric_scale_html/*"

  @doc """
  Renders a numeric_scale form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def numeric_scale_form(assigns)
end
