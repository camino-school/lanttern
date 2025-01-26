defmodule LantternWeb.StaffMemberHTML do
  use LantternWeb, :html

  embed_templates "staff_member_html/*"

  @doc """
  Renders a staff member form.
  """
  attr :school_options, :list, required: true
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def staff_member_form(assigns)
end
