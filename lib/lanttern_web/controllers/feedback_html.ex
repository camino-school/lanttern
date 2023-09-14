defmodule LantternWeb.FeedbackHTML do
  use LantternWeb, :html

  embed_templates "feedback_html/*"

  @doc """
  Renders a feedback form.
  """
  attr :assessment_point_options, :list, required: true
  attr :student_options, :list, required: true
  attr :profile_options, :list, required: true
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def feedback_form(assigns)
end
