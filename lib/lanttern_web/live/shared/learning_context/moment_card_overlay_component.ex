defmodule LantternWeb.LearningContext.MomentCardOverlayComponent do
  @moduledoc """
  Renders an overlay with `MomentCard` details and editing support.

  ### Supported attrs/assigns

  - `moment_card` (required, `%MomentCard{}`)
  - `current_user` (required, `%User{}`)
  - `on_cancel` (required, function)
  - `allow_edit` (required, boolean)
  - supports `notify` attrs (`notify_parent`, `notify_component`)
  """

  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.MomentCard
  alias Lanttern.SchoolConfig

  # shared
  alias LantternWeb.Attachments.AttachmentAreaComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id={@id} show on_cancel={@on_cancel}>
        <h4 class="mb-10 font-display font-black text-xl">
          <%= case {@is_editing, @moment_card} do
            {_, %{id: nil}} -> gettext("New moment card")
            {true, _} -> gettext("Edit moment card")
            {false, %{name: name}} -> name
          end %>
        </h4>
        <.main
          id={@id}
          is_selecting_template={@is_selecting_template}
          is_editing={@is_editing}
          allow_edit={@allow_edit}
          is_deleted={@is_deleted}
          templates={@streams.templates}
          template_instructions={@template_instructions}
          form={@form}
          moment_card={@moment_card}
          myself={@myself}
        />
        <div :if={@moment_card.id && !@is_deleted} class="pt-10 border-t border-ltrn-light mt-10">
          <.live_component
            module={AttachmentAreaComponent}
            id="moment-card-attachments"
            moment_card_id={@moment_card.id}
            title={gettext("Attachments")}
            allow_editing={@allow_edit}
            current_user={@current_user}
            notify_component={@myself}
          />
        </div>
      </.modal>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :is_selecting_template, :boolean, required: true
  attr :is_editing, :boolean, required: true
  attr :allow_edit, :boolean, required: true
  attr :is_deleted, :boolean, required: true
  attr :templates, :any, required: true, doc: "the templates stream"
  attr :template_instructions, :string, required: true
  attr :form, :any, required: true
  attr :moment_card, MomentCard, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true

  def main(%{is_selecting_template: true} = assigns) do
    ~H"""
    <p><%= gettext("Select a template from the list below to create the card") %></p>
    <.card_base class="p-4 mt-6">
      <div class="flex items-center gap-4">
        <p class="flex-1 font-bold text-base">
          <%= gettext("Create a new moment card from scratch") %>
        </p>
        <.action
          type="button"
          icon_name="hero-arrow-right-mini"
          phx-click={JS.push("select_blank_template", target: @myself)}
        >
          <%= gettext("Select") %>
        </.action>
      </div>
    </.card_base>
    <div id="templates-list" phx-update="stream">
      <.card_base :for={{dom_id, template} <- @templates} id={dom_id} class="p-4 mt-6">
        <div class="flex items-center gap-4">
          <p class="flex-1 font-bold text-base">
            <%= template.name %>
          </p>
          <.action
            type="button"
            icon_name="hero-arrow-right-mini"
            phx-click={
              JS.push("select_template",
                value: %{"template" => template.template, "instructions" => template.instructions},
                target: @myself
              )
            }
          >
            <%= gettext("Select") %>
          </.action>
        </div>
      </.card_base>
    </div>
    """
  end

  def main(%{is_editing: true, allow_edit: true} = assigns) do
    ~H"""
    <.scroll_to_top overlay_id={@id} id="form-scroll-top" />
    <.form
      id="moment-card-form"
      for={@form}
      phx-change="validate"
      phx-submit="save"
      phx-target={@myself}
    >
      <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
        <%= gettext("Oops, something went wrong! Please check the errors below.") %>
      </.error_block>
      <.input
        field={@form[:name]}
        type="text"
        label={gettext("Name")}
        class="mb-6"
        phx-debounce="1500"
      />
      <.input
        field={@form[:description]}
        type="textarea"
        label={gettext("Description")}
        class="mb-1"
        phx-debounce="1500"
      />
      <.markdown_supported class="mb-6" />
      <div
        :if={@template_instructions}
        class="p-4 border border-ltrn-teacher-accent rounded-sm mb-6 bg-ltrn-teacher-lightest"
      >
        <h6 class="font-display font-black font-lg text-ltrn-teacher-dark">
          <%= gettext("Template instructions") %>
        </h6>
        <.markdown text={@template_instructions} class="mt-4" />
      </div>
      <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
        <%= gettext("Oops, something went wrong! Please check the errors above.") %>
      </.error_block>
      <div class="flex items-center justify-end gap-6">
        <.action
          type="button"
          theme="subtle"
          size="md"
          phx-click={
            if(is_nil(@moment_card.id),
              do: JS.exec("data-cancel", to: "##{@id}"),
              else: JS.push("cancel_edit", target: @myself)
            )
          }
        >
          <%= gettext("Cancel") %>
        </.action>
        <.action type="submit" theme="primary" size="md" icon_name="hero-check">
          <%= gettext("Save") %>
        </.action>
      </div>
    </.form>
    """
  end

  def main(assigns) do
    ~H"""
    <.scroll_to_top overlay_id={@id} id="details-scroll-top" />
    <.markdown text={@moment_card.description} class="mt-6" />
    <.error_block :if={@is_deleted} class="mt-10">
      <%= gettext("This card was deleted") %>
    </.error_block>
    <div :if={!@is_deleted && @allow_edit} class="flex justify-between gap-4 mt-10">
      <.action
        type="button"
        icon_name="hero-x-circle-mini"
        phx-click={JS.push("delete", target: @myself)}
        theme="subtle"
        data-confirm={gettext("Are you sure?")}
      >
        <%= gettext("Delete") %>
      </.action>
      <.action type="button" icon_name="hero-pencil-mini" phx-click={JS.push("edit", target: @myself)}>
        <%= gettext("Edit card") %>
      </.action>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:form, nil)
      |> assign(:template_instructions, nil)
      |> assign(:is_editing, false)
      |> assign(:is_deleted, false)
      |> assign(:allow_edit, false)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  # handle attachment count changes
  def update(%{action: {AttachmentAreaComponent, {action, _}}}, socket)
      when action in [:deleted, :created] do
    count =
      case action do
        :deleted -> socket.assigns.moment_card.attachments_count - 1
        :created -> socket.assigns.moment_card.attachments_count + 1
      end

    moment_card = %{
      socket.assigns.moment_card
      | attachments_count: count
    }

    notify(__MODULE__, {:updated, moment_card}, socket.assigns)

    {:ok, assign(socket, :moment_card, moment_card)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_templates()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_templates(%{assigns: %{moment_card: %{id: nil}}} = socket) do
    templates =
      SchoolConfig.list_moment_cards_templates(
        school_id: socket.assigns.current_user.current_profile.school_id
      )

    if templates == [] do
      # skip template selection if there's no template registered
      socket
      |> stream(:templates, [])
      |> assign(:is_selecting_template, false)
      |> assign_form()
      |> assign(:is_editing, true)
    else
      socket
      |> stream(:templates, templates)
      |> assign(:is_selecting_template, true)
    end
  end

  defp stream_templates(socket) do
    socket
    |> stream(:templates, [])
    |> assign(:is_selecting_template, false)
  end

  defp assign_form(socket) do
    changeset = LearningContext.change_moment_card(socket.assigns.moment_card)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("select_blank_template", _params, socket) do
    socket =
      socket
      |> assign_form()
      |> assign(:is_selecting_template, false)
      |> assign(:is_editing, true)

    {:noreply, socket}
  end

  def handle_event(
        "select_template",
        %{"template" => template, "instructions" => instructions},
        socket
      ) do
    moment_card =
      %{
        socket.assigns.moment_card
        | description: template
      }

    socket =
      socket
      |> assign(:moment_card, moment_card)
      |> assign(:template_instructions, instructions)
      |> assign_form()
      |> assign(:is_selecting_template, false)
      |> assign(:is_editing, true)

    {:noreply, socket}
  end

  def handle_event("edit", _, socket) do
    socket =
      socket
      |> assign_form()
      |> assign(:is_editing, true)

    {:noreply, socket}
  end

  def handle_event("cancel_edit", _, socket),
    do: {:noreply, assign(socket, :is_editing, false)}

  def handle_event("validate", %{"moment_card" => moment_card_params}, socket),
    do: {:noreply, assign_validated_form(socket, moment_card_params)}

  def handle_event("save", %{"moment_card" => moment_card_params}, socket) do
    save_moment_card(
      socket,
      socket.assigns.moment_card.id,
      moment_card_params
    )
  end

  def handle_event("delete", _, socket) do
    LearningContext.delete_moment_card(socket.assigns.moment_card)
    |> case do
      {:ok, _moment_card} ->
        # we notify using the assigned moment card
        notify(__MODULE__, {:deleted, socket.assigns.moment_card}, socket.assigns)

        socket =
          socket
          |> assign(:is_deleted, true)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    changeset =
      socket.assigns.moment_card
      |> LearningContext.change_moment_card(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  defp save_moment_card(socket, nil, moment_card_params) do
    # inject moment id to params
    moment_card_params =
      Map.put_new(
        moment_card_params,
        "moment_id",
        socket.assigns.moment_card.moment_id
      )

    LearningContext.create_moment_card(moment_card_params)
    |> case do
      {:ok, moment_card} ->
        notify(__MODULE__, {:created, moment_card}, socket.assigns)

        socket =
          socket
          |> assign(:moment_card, moment_card)
          |> assign(:is_editing, false)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_moment_card(socket, _id, moment_card_params) do
    LearningContext.update_moment_card(
      socket.assigns.moment_card,
      moment_card_params
    )
    |> case do
      {:ok, moment_card} ->
        notify(__MODULE__, {:updated, moment_card}, socket.assigns)

        socket =
          socket
          |> assign(:moment_card, moment_card)
          |> assign(:is_editing, false)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
