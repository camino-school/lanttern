defmodule LantternWeb.OrdinalValueHTML do
  use LantternWeb, :html

  embed_templates "ordinal_value_html/*"

  @doc """
  Renders a ordinal_value form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :scale_options, :list, required: true

  def ordinal_value_form(assigns)
end
