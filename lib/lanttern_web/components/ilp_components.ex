defmodule LantternWeb.ILPComponents do
  @moduledoc """
  Shared function components related to `ILP` context
  """

  use Phoenix.Component

  use Gettext, backend: Lanttern.Gettext

  use LantternWeb, :live_component
  import LantternWeb.CoreComponents
  import LantternWeb.DateTimeHelpers

  alias Lanttern.Identity
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

  attr :ilp_comments, :list, default: []
  attr :current_profile, :map
  attr :tz, :string, default: nil

  def ilp_comments_list(assigns) do
    ~H"""
      <br /><br />
      <div  id="all_comments">
        <h5 class="flex items-center gap-2 text-ltrn-subtle">
          <div class="w-10 text-center">
            <.icon name="hero-chat-bubble-left-right" class="w-6 h-6" />
          </div>
          <span class="font-display font-black text-xl"><%= gettext("ILP comments") %></span>
        </h5>

        <.empty_state_simple :if={Enum.empty?(@ilp_comments)} class="mt-6">
          <%= gettext("No comments in this ILP yet") %>
        </.empty_state_simple>

        <div
          :for={ilp_comment <- @ilp_comments}
          class={[
            "flex items-start gap-2 w-full mt-6",
            if(ilp_comment.owner_id == @current_profile.id, do: "flex-row-reverse")
          ]}
          id={"ilp-comment-#{ilp_comment.id}"}
        >
          <.profile_picture
            picture_url={ilp_comment.owner.profile_picture_url}
            profile_name={ilp_comment.owner.name}
          />
          <.card_base class="flex-1 max-w-3/4 p-2">
            <div class="flex items-center justify-between gap-4">
              <div class="flex items-center gap-4">
                <div class="flex-1 font-bold text-xs text-ltrn-staff-dark">
                  <%= Identity.get_profile_name(ilp_comment.owner_id) %>
                </div>
                <.badge theme="staff"><%= gettext("Staff") %></.badge>
              </div>
              <.action
                :if={ilp_comment.owner_id == @current_profile.id}
                type="link"
                icon_name="hero-pencil-mini"
                patch={"?comment_id=#{ilp_comment.id}"}
                theme="subtle"
                id={"edit-comment-#{ilp_comment.id}"}
              >
                <%= gettext("Edit") %>
              </.action>
            </div>
            <div class="flex items-end justify-between gap-2 mt-4">
              <.markdown text={ilp_comment.content} class="flex-1" />
              <div class="text-ltrn-subtle text-xs">
                <%= format_by_locale(ilp_comment.inserted_at, @tz) %>
              </div>
            </div>
            <div
              :if={!Enum.empty?(ilp_comment.attachments)}
              class="p-2 rounded-sm mt-4 bg-ltrn-lightest"
            >
              <h6 class="flex items-center gap-2 font-bold text-ltrn-subtle">
                <.icon name="hero-paper-clip-mini" />
                <%= gettext("Attachments") %>
              </h6>
              <div :for={ilp_attachment <- ilp_comment.attachments}>
                <.card_base class="p-4 mt-2">
                  <%= if(ilp_attachment.is_external) do %>
                    <.badge><%= gettext("External link") %></.badge>
                  <% else %>
                    <.badge theme="cyan"><%= gettext("Upload") %></.badge>
                  <% end %>
                  <a
                    href={ilp_attachment.link}
                    target="_blank"
                    class="block mt-2 text-sm underline hover:text-ltrn-subtle"
                  >
                    <%= ilp_attachment.name %>
                  </a>
                </.card_base>
              </div>
            </div>
          </.card_base>
        </div>
        <div class="flex flex-row-reverse items-center gap-2 w-full mt-6">
          <.profile_picture
            picture_url={@current_profile.profile_picture_url}
            profile_name={@current_profile.name}
          />
          <.card_base class="flex-1 flex max-w-3/4 p-4">
            <.action
              type="link"
              patch="?comment=new"
              icon_name="hero-plus-circle-mini"
              theme="primary"
            >
              <%= gettext("Add ILP comment") %>
            </.action>
          </.card_base>
        </div>
      </div>
    """
  end
end
