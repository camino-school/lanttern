defmodule LantternWeb.SubjectHTML do
  use LantternWeb, :html

  embed_templates "subject_html/*"

  @doc """
  Renders a subject form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def subject_form(assigns)
end
