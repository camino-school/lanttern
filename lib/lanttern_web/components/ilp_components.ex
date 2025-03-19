defmodule LantternWeb.ILPComponents do
  @moduledoc """
  Shared function components related to `ILP` context
  """

  use Phoenix.Component

  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents

  alias Lanttern.ILP.StudentILP

  @doc """
  Renders a student ILP share controls.
  """

  attr :student_ilp, StudentILP, required: true
  attr :show_controls, :boolean, default: false
  attr :on_student_share_toggle, :any, default: nil
  attr :on_guardians_share_toggle, :any, default: nil
  attr :class, :any, default: nil
  attr :id, :string, default: nil

  def student_ilp_share_controls(assigns) do
    ~H"""
    <div class={["flex item-center gap-2", @class]} id={@id}>
      <div class="group relative shrink-0 flex items-center gap-1">
        <.toggle
          :if={@show_controls}
          enabled={@student_ilp.is_shared_with_student}
          theme="student"
          phx-click={@on_student_share_toggle}
        />
        <.icon
          name="hero-user-mini"
          class={
            if !@student_ilp.is_shared_with_student,
              do: "text-ltrn-light",
              else: "text-ltrn-student-dark"
          }
        />
        <.tooltip h_pos="right">
          <%= if @student_ilp.is_shared_with_student,
            do: gettext("Shared with student"),
            else: gettext("Not shared with student") %>
        </.tooltip>
      </div>
      <div class="group relative shrink-0 flex items-center gap-1">
        <.toggle
          :if={@show_controls}
          enabled={@student_ilp.is_shared_with_guardians}
          theme="student"
          phx-click={@on_guardians_share_toggle}
        />
        <.icon
          name="hero-users-mini"
          class={
            if !@student_ilp.is_shared_with_guardians,
              do: "text-ltrn-light",
              else: "text-ltrn-student-dark"
          }
        />
        <.tooltip h_pos="right">
          <%= if @student_ilp.is_shared_with_guardians,
            do: gettext("Shared with guardians"),
            else: gettext("Not shared with guardians") %>
        </.tooltip>
      </div>
    </div>
    """
  end
end
