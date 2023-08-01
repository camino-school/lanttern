defmodule LantternWeb.ConversionRuleHTML do
  use LantternWeb, :html

  embed_templates "conversion_rule_html/*"

  @doc """
  Renders a conversion_rule form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :scale_options, :list, required: true

  def conversion_rule_form(assigns)
end
