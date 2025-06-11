defmodule LantternWeb.QuizzesComponents do
  @moduledoc """
  Shared function components related to `Quizzes` context
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.OverlayComponents

  alias LantternWeb.Quizzes.QuizFormComponent

  @doc """
  Renders a list of quizzes
  """

  attr :quizzes, :any, required: true
  attr :edit_patch_fn, :any, required: true, doc: "will receive quiz_id as arg"
  attr :on_delete_fn, :any, required: true, doc: "will receive quiz_id as arg"
  attr :id, :string, required: true
  attr :class, :any, default: nil

  def quizzes_list(assigns) do
    ~H"""
    <div id={@id} class={@class} phx-update="stream">
      <.empty_state id={"empty-#{@id}"} class="only:block hidden">
        <%= gettext("No quizzes") %>
      </.empty_state>
      <.card_base :for={{dom_id, quiz} <- @quizzes} id={dom_id} class="p-6 mt-6">
        <%= quiz.title %>
        <.markdown text={quiz.description} />
        <.action type="link" patch={@edit_patch_fn.(quiz.id)}><%= gettext("Edit") %></.action>
        <.action
          type="button"
          phx-click={@on_delete_fn.(quiz.id)}
          data-confirm={gettext("Are you sure?")}
        >
          <%= gettext("Delete") %>
        </.action>
      </.card_base>
    </div>
    """
  end

  @doc """
  Renders quiz form overlay
  """

  attr :quiz, :any, required: true
  attr :id, :string, required: true
  attr :on_cancel, JS, default: %JS{}

  def quiz_form_overlay(assigns) do
    ~H"""
    <.modal :if={@quiz} show on_cancel={@on_cancel} id={@id}>
      <h4 class="mb-10 font-display font-black text-xl">
        <%= case @quiz.id do
          nil -> gettext("New quiz")
          _ -> gettext("Edit quiz")
        end %>
      </h4>
      <.live_component
        id={"#{@id}-form"}
        module={QuizFormComponent}
        quiz={@quiz}
        on_cancel={@on_cancel}
        notify_parent
      />
    </.modal>
    """
  end
end
