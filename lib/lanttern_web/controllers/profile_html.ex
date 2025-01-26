defmodule LantternWeb.ProfileHTML do
  use LantternWeb, :html

  embed_templates "profile_html/*"

  @doc """
  Renders a profile form.
  """
  attr :user_options, :list, required: true
  attr :student_options, :list, required: true
  attr :staff_member_options, :list, required: true
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def profile_form(assigns)
end
