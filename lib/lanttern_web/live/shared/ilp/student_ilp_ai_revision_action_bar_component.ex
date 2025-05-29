defmodule LantternWeb.ILP.StudentILPAIRevisionActionBarComponent do
  @moduledoc """
  Renders an ILP AI revision action bar.
  ### Required attrs
  - `:current_profile`
  - `:view_patch`
  - `:ilp_template` - `%ILPTemplate{}`
  - `:student_ilp` - `%StudentILP{}`
  ### Optional attrs
  - `:class`
  - `:notify_parent` - boolean
  - `:notify_component` - `Phoenix.LiveComponent.CID`
  ### Notifications
  - {`:generate_success`, %StudentILP{}}
  """

  use LantternWeb, :live_component

  alias Lanttern.ILP
  alias Lanttern.ILP.ILPTemplate
  alias Lanttern.ILP.StudentILP

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <.ai_action_bar name={gettext("LantternAI ILP revision")}>
        <%= if @has_ai_revision do %>
          <div class="flex items-center gap-2">
            <.action type="link" patch={@view_patch} theme="ai">
              <%= gettext("View") %>
            </.action>
            <.ai_content_indicator />
          </div>
        <% else %>
          <form :if={@ai_form} phx-submit="generate" phx-target={@myself}>
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
                <%= gettext("Generate revision") %>
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
      </.ai_action_bar>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:generate_error, nil)
      |> assign(:ai_form_error, nil)
      |> assign(:ai_response_error, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> ensure_template_ai_layer_is_loaded()
    |> assign_has_ai_revision()
    |> assign_ai_form()
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

  defp assign_has_ai_revision(socket) do
    has_ai_revision =
      case socket.assigns.student_ilp do
        %StudentILP{ai_revision: revision} when not is_nil(revision) -> true
        _ -> false
      end

    assign(socket, :has_ai_revision, has_ai_revision)
  end

  defp assign_ai_form(
         %{
           assigns: %{
             has_ai_revision: false,
             ilp_template: %ILPTemplate{},
             student_ilp: %StudentILP{}
           }
         } = socket
       ) do
    # we enable the AI form only if
    # - ILP has all entries
    # - there's no AI revision (only the view button is displayed in this case)
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
              notify(__MODULE__, {:generate_success, student_ilp}, socket.assigns)

              socket
              |> assign(:student_ilp, student_ilp)
              |> assign_has_ai_revision()
              |> assign(:ai_response_error, nil)
              |> assign(:ai_form_error, nil)

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
