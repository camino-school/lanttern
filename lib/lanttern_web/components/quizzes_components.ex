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
  alias LantternWeb.Quizzes.QuizItemFormComponent

  @doc """
  Renders a list of quizzes
  """

  attr :quizzes, :any, required: true
  attr :show_patch_fn, :any, required: true, doc: "will receive quiz_id as arg"
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
        <.link patch={@show_patch_fn.(quiz.id)} class="mb-6 font-display font-black text-xl">
          <%= quiz.title %>
        </.link>
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
  Renders a list of quiz items
  """

  attr :quiz_items, :any, required: true
  attr :edit_patch_fn, :any, required: true, doc: "will receive quiz item id as arg"
  attr :on_delete_fn, :any, required: true, doc: "will receive quiz item id as arg"
  attr :id, :string, required: true
  attr :class, :any, default: nil

  def quiz_items_list(assigns) do
    ~H"""
    <div id={@id} class={@class} phx-update="stream">
      <.empty_state_simple id={"empty-#{@id}"} class="only:block hidden">
        <%= gettext("No quiz items") %>
      </.empty_state_simple>
      <.card_base :for={{dom_id, quiz_item} <- @quiz_items} id={dom_id} class="p-6 mt-6">
        <.badge>
          <%= case quiz_item.type do
            :multiple_choice -> gettext("Multiple choice")
            :text -> gettext("Text")
          end %>
        </.badge>
        <.markdown text={quiz_item.description} />
        <.action type="link" patch={@edit_patch_fn.(quiz_item.id)}><%= gettext("Edit") %></.action>
        <.action
          type="button"
          phx-click={@on_delete_fn.(quiz_item.id)}
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

  @doc """
  Renders quiz item form overlay
  """

  attr :quiz_item, :any, required: true
  attr :id, :string, required: true
  attr :on_cancel, JS, default: %JS{}

  def quiz_item_form_overlay(assigns) do
    ~H"""
    <.modal :if={@quiz_item} show on_cancel={@on_cancel} id={@id}>
      <h4 class="mb-10 font-display font-black text-xl">
        <%= case @quiz_item.id do
          nil -> gettext("New quiz item")
          _ -> gettext("Edit quiz item")
        end %>
      </h4>
      <.live_component
        id={"#{@id}-form"}
        module={QuizItemFormComponent}
        quiz_item={@quiz_item}
        on_cancel={@on_cancel}
        notify_parent
      />
    </.modal>
    """
  end
end
