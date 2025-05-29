defmodule LantternWeb.ILP.StudentILPAIRevisionOverlayComponent do
  @moduledoc """
  Renders an overlay with the student ILP revision.

  If there's no student ILP revision, nothing is rendered.

  ### Required attrs

  - `:current_profile`
  - `:tz`
  - `:on_cancel`
  - `:ilp_template` - `%ILPTemplate{}`
  - `:student_ilp` - `%StudentILP{}`

  """

  use LantternWeb, :live_component

  alias Lanttern.ILP
  alias Lanttern.ILP.ILPTemplate
  alias Lanttern.ILP.StudentILP

  import LantternWeb.DateTimeHelpers, only: [format_by_locale: 2]

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.ai_panel_overlay
        :if={@has_ai_revision}
        id={"#{@id}-ai-panel"}
        show
        on_cancel={@on_cancel}
        panel_title={gettext("LantternAI ILP revision")}
        class="p-4"
      >
        <p class="mb-6 text-xs">
          <%= gettext("Generated in %{datetime}",
            datetime: format_by_locale(@student_ilp.ai_revision_datetime, @tz)
          ) %>
        </p>
        <.markdown text={@student_ilp.ai_revision} />
        <.ai_generated_content_disclaimer class="mt-4" />
        <%= if @is_on_ai_cooldown do %>
          <.card_base class="p-2 mt-4">
            <p class="flex items-center gap-2 text-ltrn-ai-dark">
              <.icon name="hero-clock-micro" class="w-4 h-4" />
              <%= gettext("AI revision can be requested every %{minute} minutes",
                minute: @ai_cooldown_minutes
              ) %>
              <%= ngettext(
                "(1 minute left until next revision request)",
                "(%{count} minutes left until next revision request)",
                @ai_cooldown_minutes_left
              ) %>
            </p>
          </.card_base>
        <% else %>
          <form
            :if={@ai_form}
            phx-submit="generate"
            phx-target={@myself}
            class="pt-6 border-t border-ltrn-ai-light mt-6"
          >
            <div class="flex items-center gap-4">
              <div class="w-32">
                <.base_input
                  name={@ai_form[:age].name}
                  type="number"
                  placeholder={gettext("Student age")}
                  value={@ai_form[:age].value}
                />
              </div>
              <.action type="submit" icon_name="hero-sparkles-mini" theme="ai-generate">
                <%= gettext("Update revision") %>
              </.action>
            </div>
            <p :if={@ai_form_error} class="flex items-center gap-2 mt-2 text-xs">
              <.icon name="hero-exclamation-circle-micro" class="w-4 h-4" />
              <%= @ai_form_error %>
            </p>
            <p :if={@ai_response_error} class="flex items-center gap-2 mt-2 text-xs">
              <.icon name="hero-exclamation-circle-micro" class="w-4 h-4" />
              <%= @ai_response_error %>
            </p>
          </form>
        <% end %>
      </.ai_panel_overlay>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:ai_form_error, nil)
      |> assign(:ai_response_error, nil)
      |> assign(:generate_error, nil)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> ensure_template_ai_layer_is_loaded()
    |> assign_ai_form()
    |> assign_has_ai_revision()
    |> assign_is_on_ai_cooldown()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp ensure_template_ai_layer_is_loaded(
         %{assigns: %{ilp_template: %ILPTemplate{ai_layer: %Ecto.Association.NotLoaded{}}}} =
           socket
       ) do
    template =
      socket.assigns.ilp_template
      |> Lanttern.Repo.preload(:ai_layer)

    assign(socket, :ilp_template, template)
  end

  defp ensure_template_ai_layer_is_loaded(socket), do: socket

  defp assign_ai_form(
         %{assigns: %{ilp_template: %ILPTemplate{}, student_ilp: %StudentILP{}}} = socket
       ) do
    # we enable the AI form only if
    # - ILP has all entries
    # - template has AI revision instructions
    # - template has a selected AI model

    has_all_entries =
      socket.assigns.student_ilp.entries
      |> Enum.all?(&(not is_nil(&1.description)))

    template_ai_layer_is_ok =
      socket.assigns.ilp_template.ai_layer &&
        not is_nil(socket.assigns.ilp_template.ai_layer.revision_instructions) &&
        not is_nil(socket.assigns.ilp_template.ai_layer.model)

    if has_all_entries && template_ai_layer_is_ok do
      form = to_form(%{"age" => nil}, as: :ai_form)
      assign(socket, :ai_form, form)
    else
      assign(socket, :ai_form, nil)
    end
  end

  defp assign_ai_form(socket) do
    assign(socket, :ai_form, nil)
  end

  defp assign_has_ai_revision(socket) do
    has_ai_revision =
      case socket.assigns.student_ilp do
        %StudentILP{ai_revision: revision} when not is_nil(revision) -> true
        _ -> false
      end

    assign(socket, :has_ai_revision, has_ai_revision)
  end

  defp assign_is_on_ai_cooldown(%{assigns: %{has_ai_revision: true}} = socket) do
    ai_cooldown_minutes =
      (socket.assigns.ilp_template.ai_layer &&
         socket.assigns.ilp_template.ai_layer.cooldown_minutes) || 0

    cooldown_end_datetime =
      DateTime.shift(socket.assigns.student_ilp.ai_revision_datetime, minute: ai_cooldown_minutes)

    is_on_ai_cooldown =
      DateTime.before?(DateTime.utc_now(), cooldown_end_datetime)

    ai_cooldown_minutes_left =
      Timex.diff(
        cooldown_end_datetime,
        DateTime.utc_now(),
        :minutes
      )

    socket
    |> assign(:is_on_ai_cooldown, is_on_ai_cooldown)
    |> assign(:ai_cooldown_minutes, ai_cooldown_minutes)
    |> assign(:ai_cooldown_minutes_left, ai_cooldown_minutes_left)
  end

  defp assign_is_on_ai_cooldown(socket),
    do: assign(socket, :is_on_ai_cooldown, false)

  # event handlers

  @impl true
  def handle_event("generate", %{"ai_form" => %{"age" => age}}, socket) do
    socket =
      case Integer.parse(age) do
        {age, ""} ->
          ILP.revise_student_ilp(
            socket.assigns.student_ilp,
            socket.assigns.ilp_template,
            age,
            log_profile_id: socket.assigns.current_profile.id
          )
          |> case do
            {:ok, student_ilp} ->
              socket
              |> assign(:student_ilp, student_ilp)
              |> assign_has_ai_revision()
              |> assign(:ai_response_error, nil)
              |> assign(:ai_form_error, nil)
              |> assign_is_on_ai_cooldown()

            _ ->
              socket
              |> assign(:ai_response_error, gettext("AI revision failed"))
              |> assign(:ai_form_error, nil)
          end

        _ ->
          error = gettext("Age is required")
          assign(socket, :ai_form_error, error)
      end

    {:noreply, socket}
  end
end
