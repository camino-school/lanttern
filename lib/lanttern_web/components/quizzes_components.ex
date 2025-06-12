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
  Renders a list of quizzes.
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
      <.card_base :for={{dom_id, quiz} <- @quizzes} id={dom_id} class="p-6 mt-6 first:mt-0">
        <div class="flex items-start gap-4 mb-6">
          <.link
            patch={@show_patch_fn.(quiz.id)}
            class="flex-1 font-display font-black text-xl hover:text-ltrn-subtle"
          >
            <%= quiz.title %>
          </.link>
          <div class="shrink-0 flex gap-2">
            <.action type="link" patch={@edit_patch_fn.(quiz.id)} icon_name="hero-pencil-mini">
              <%= gettext("Edit") %>
            </.action>
            <.menu_button id={"menu-#{@id}-quiz-#{quiz.id}"}>
              <:item
                id={"delete-#{@id}-quiz-#{quiz.id}"}
                text={gettext("Delete quiz")}
                on_click={@on_delete_fn.(quiz.id)}
                theme="alert"
                confirm_msg={gettext("Are you sure?")}
              />
            </.menu_button>
          </div>
        </div>
        <.markdown text={quiz.description} />
      </.card_base>
      <.empty_state id={"empty-#{@id}"} class="only:block hidden">
        <%= gettext("No quizzes") %>
      </.empty_state>
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
      <.card_base :for={{dom_id, quiz_item} <- @quiz_items} id={dom_id} class="p-6 mt-6 first:mt-0">
        <div class="flex items-center gap-4">
          <div class="flex-1">
            <.badge>
              <%= case quiz_item.type do
                :multiple_choice -> gettext("Multiple choice")
                :text -> gettext("Text")
              end %>
            </.badge>
            <.markdown text={quiz_item.description} />
          </div>
          <div class="shrink-0 flex gap-2">
            <.action type="link" patch={@edit_patch_fn.(quiz_item.id)} icon_name="hero-pencil-mini">
              <%= gettext("Edit") %>
            </.action>
            <.menu_button id={"menu-#{@id}-quiz-item-#{quiz_item.id}"}>
              <:item
                id={"delete-#{@id}-quiz-item-#{quiz_item.id}"}
                text={gettext("Delete quiz")}
                on_click={@on_delete_fn.(quiz_item.id)}
                theme="alert"
                confirm_msg={gettext("Are you sure?")}
              />
            </.menu_button>
          </div>
        </div>
      </.card_base>
      <.empty_state_simple id={"empty-#{@id}"} class="only:block hidden">
        <%= gettext("No quiz items") %>
      </.empty_state_simple>
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
