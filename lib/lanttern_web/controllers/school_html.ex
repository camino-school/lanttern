defmodule LantternWeb.SchoolHTML do
  use LantternWeb, :html

  embed_templates "school_html/*"

  @doc """
  Renders a school form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def school_form(assigns)
end
