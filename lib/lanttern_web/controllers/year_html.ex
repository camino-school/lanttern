defmodule LantternWeb.YearHTML do
  use LantternWeb, :html

  embed_templates "year_html/*"

  @doc """
  Renders a year form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def year_form(assigns)
end
