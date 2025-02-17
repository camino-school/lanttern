defmodule LantternWeb.SchoolConfig.MomentCardTemplateOverlayComponent do
  @moduledoc """
  Renders an overlay with `MomentCardTemplate` details and editing support.

  ### Supported attrs/assigns

  - `moment_card_template` (required, `%MomentCardTemplate{}`)
  - `on_cancel` (required, function)
  - `allow_edit` (required, boolean)
  - supports `notify` attrs (`notify_parent`, `notify_component`)
  """

  use LantternWeb, :live_component

  alias Lanttern.SchoolConfig

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id={@id} show on_cancel={@on_cancel}>
        <h5 class="mb-10 font-display font-black text-xl">
          <%= case {@is_editing, @moment_card_template} do
            {true, %{id: nil}} -> gettext("New moment card template")
            {true, _} -> gettext("Edit moment card template")
            {false, %{name: name}} -> gettext("Template: %{template}", template: name)
          end %>
        </h5>
        <%= if @is_editing && @allow_edit do %>
          <.scroll_to_top overlay_id={@id} id="form-scroll-top" />
          <.form
            :if={@is_editing}
            id="moment-card-template-form"
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
              field={@form[:template]}
              type="textarea"
              label={gettext("Template")}
              class="mb-1"
              phx-debounce="1500"
            />
            <.markdown_supported class="mb-6" />
            <.input
              field={@form[:instructions]}
              type="textarea"
              label={gettext("Additional instructions")}
              class="mb-1"
              phx-debounce="1500"
              show_optional
            />
            <.markdown_supported class="mb-6" />
            <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
              <%= gettext("Oops, something went wrong! Please check the errors above.") %>
            </.error_block>
            <div class="flex items-center justify-end gap-6">
              <.action
                type="button"
                theme="subtle"
                size="md"
                phx-click={
                  if(is_nil(@moment_card_template.id),
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
        <% else %>
          <.scroll_to_top overlay_id={@id} id="details-scroll-top" />
          <.markdown text={@moment_card_template.template} class="mt-6" />
          <div
            :if={@moment_card_template.instructions}
            class="p-4 border border-ltrn-staff-accent rounded-sm mt-10 bg-ltrn-staff-lightest"
          >
            <h6 class="font-display font-black font-lg text-ltrn-staff-dark">
              <%= gettext("Additional teacher instructions") %>
            </h6>
            <.markdown text={@moment_card_template.instructions} class="mt-6" />
          </div>
          <%= if @is_deleted do %>
            <.error_block class="mt-10">
              <%= gettext("This template was deleted") %>
            </.error_block>
          <% else %>
            <div :if={@allow_edit} class="flex justify-between gap-4 mt-10">
              <.action
                type="button"
                icon_name="hero-x-circle-mini"
                phx-click={JS.push("delete", target: @myself)}
                theme="subtle"
                data-confirm={gettext("Are you sure?")}
              >
                <%= gettext("Delete") %>
              </.action>
              <.action
                type="button"
                icon_name="hero-pencil-mini"
                phx-click={JS.push("edit", target: @myself)}
              >
                <%= gettext("Edit template") %>
              </.action>
            </div>
          <% end %>
        <% end %>
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:is_deleted, false)
      |> assign(:allow_edit, false)
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

  defp initialize(socket) do
    socket
    |> assign_initial_is_editing()
    |> assign(:initialized, true)
  end

  defp assign_initial_is_editing(%{assigns: %{moment_card_template: %{id: nil}}} = socket) do
    socket
    |> assign_form()
    |> assign(:is_editing, true)
  end

  defp assign_initial_is_editing(socket),
    do: assign(socket, :is_editing, false)

  defp assign_form(socket) do
    changeset = SchoolConfig.change_moment_card_template(socket.assigns.moment_card_template)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("edit", _, socket) do
    socket =
      socket
      |> assign_form()
      |> assign(:is_editing, true)

    {:noreply, socket}
  end

  def handle_event("cancel_edit", _, socket),
    do: {:noreply, assign(socket, :is_editing, false)}

  def handle_event("validate", %{"moment_card_template" => moment_card_template_params}, socket),
    do: {:noreply, assign_validated_form(socket, moment_card_template_params)}

  def handle_event("save", %{"moment_card_template" => moment_card_template_params}, socket) do
    save_moment_card_template(
      socket,
      socket.assigns.moment_card_template.id,
      moment_card_template_params
    )
  end

  def handle_event("delete", _, socket) do
    SchoolConfig.delete_moment_card_template(socket.assigns.moment_card_template)
    |> case do
      {:ok, _moment_card_template} ->
        # we notify using the assigned moment card template
        notify(__MODULE__, {:deleted, socket.assigns.moment_card_template}, socket.assigns)

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
      socket.assigns.moment_card_template
      |> SchoolConfig.change_moment_card_template(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  defp save_moment_card_template(socket, nil, moment_card_template_params) do
    # inject school id to params
    moment_card_template_params =
      Map.put_new(
        moment_card_template_params,
        "school_id",
        socket.assigns.moment_card_template.school_id
      )

    SchoolConfig.create_moment_card_template(moment_card_template_params)
    |> case do
      {:ok, moment_card_template} ->
        notify(__MODULE__, {:created, moment_card_template}, socket.assigns)

        socket =
          socket
          |> assign(:moment_card_template, moment_card_template)
          |> assign(:is_editing, false)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_moment_card_template(socket, _id, moment_card_template_params) do
    SchoolConfig.update_moment_card_template(
      socket.assigns.moment_card_template,
      moment_card_template_params
    )
    |> case do
      {:ok, moment_card_template} ->
        notify(__MODULE__, {:updated, moment_card_template}, socket.assigns)

        socket =
          socket
          |> assign(:moment_card_template, moment_card_template)
          |> assign(:is_editing, false)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
