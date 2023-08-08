defmodule LantternWeb.AssessmentPointHTML do
  use LantternWeb, :html

  embed_templates "assessment_point_html/*"

  @doc """
  Renders a assessment form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :curriculum_item_options, :list, required: true
  attr :scale_options, :list, required: true

  def assessment_point_form(assigns)
end
