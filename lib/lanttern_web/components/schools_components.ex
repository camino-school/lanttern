defmodule LantternWeb.SchoolsComponents do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.OverlayComponents

  @doc """
  Renders a class selection overlay.
  """
  attr :current_user, Lanttern.Identity.User, required: true
  attr :classes_ids, :list, required: true
  attr :id, :string, required: true
  attr :notify_parent, :boolean, default: false
  attr :notify_component, Phoenix.LiveComponent.CID, default: nil
  attr :on_clear, JS, default: nil
  attr :navigate, :any, default: nil
  attr :patch, :any, default: nil

  def class_selection_overlay(assigns) do
    ~H"""
    <.slide_over id={@id}>
      <:title><%= gettext("Classes") %></:title>
      <.live_component
        module={LantternWeb.Schools.ClassFilterFormComponent}
        id={:filter}
        current_user={@current_user}
        classes_ids={@classes_ids}
        navigate={@navigate}
        patch={@patch}
        notify_parent={@notify_parent}
        notify_component={@notify_component}
      />
      <:actions_left :if={@on_clear}>
        <.button type="button" theme="ghost" phx-click={@on_clear}>
          <%= gettext("Clear filters") %>
        </.button>
      </:actions_left>
      <:actions>
        <.button type="button" theme="ghost" phx-click={JS.exec("data-cancel", to: "##{@id}")}>
          <%= gettext("Cancel") %>
        </.button>
        <.button
          type="submit"
          form="class-filter-form"
          phx-click={JS.exec("data-cancel", to: "##{@id}")}
        >
          <%= gettext("Select") %>
        </.button>
      </:actions>
    </.slide_over>
    """
  end
end
