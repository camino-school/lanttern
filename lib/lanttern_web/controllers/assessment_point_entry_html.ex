defmodule LantternWeb.AssessmentPointEntryHTML do
  use LantternWeb, :html

  embed_templates "assessment_point_entry_html/*"

  @doc """
  Renders a assessment_point_entry form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :assessment_point_options, :list, required: true
  attr :student_options, :list, required: true
  attr :ordinal_value_options, :list, required: true

  def assessment_point_entry_form(assigns)
end
