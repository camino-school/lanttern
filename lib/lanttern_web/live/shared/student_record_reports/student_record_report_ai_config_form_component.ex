defmodule LantternWeb.StudentRecordReports.StudentRecordReportAIConfigFormComponent do
  @moduledoc """
  Renders an `StudentRecordReportAIConfig` form.

  ### Attrs

  - `:config` - `StudentRecordReportAIConfig`, required
  - `:class`
  - `:notify_parent` - boolean
  - `:notify_component` - `Phoenix.LiveComponent.CID`

  """

  use LantternWeb, :live_component

  alias Lanttern.StudentRecordReports

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form id={@id} for={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
        <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
          <%= gettext("Oops, something went wrong! Please check the errors below.") %>
        </.error_block>
        <.input
          field={@form[:summary_instructions]}
          type="textarea"
          label={gettext("Generate summary instructions")}
          phx-debounce="1500"
          class="mb-1"
          show_optional
        />
        <.markdown_supported class="mb-6" />
        <.input
          field={@form[:update_instructions]}
          type="textarea"
          label={gettext("Generate update instructions")}
          phx-debounce="1500"
          class="mb-1"
          show_optional
        />
        <.markdown_supported class="mb-6" />
        <.input
          field={@form[:about]}
          type="textarea"
          label={gettext("About")}
          phx-debounce="1500"
          class="mb-1"
          show_optional
        >
          <:description>
            <p><%= gettext("This will be displayed in LantternAI overlay.") %></p>
          </:description>
        </.input>
        <.markdown_supported class="mb-6" />
        <.input
          field={@form[:model]}
          type="select"
          label="AI model"
          options={@ai_model_options}
          prompt={
            if @ai_model_options == [], do: gettext("Loading..."), else: gettext("Select an AI model")
          }
          class="mb-6"
        />
        <.input
          field={@form[:cooldown_minutes]}
          type="number"
          label={gettext("AI request cooldown (minutes)")}
          class="mb-6"
        />
        <div class="flex items-center justify-between gap-4">
          <div>
            <.action
              :if={@config.id}
              type="button"
              size="md"
              theme="subtle"
              phx-click={JS.push("delete", target: @myself)}
              data-confirm={gettext("Are you sure?")}
            >
              <%= gettext("Clear instructions") %>
            </.action>
          </div>
          <div class="flex items-center gap-4">
            <.action type="button" size="md" phx-click={JS.push("cancel", target: @myself)}>
              <%= gettext("Cancel") %>
            </.action>
            <.action type="submit" theme="ai" size="md" icon_name="hero-check">
              <%= gettext("Save") %>
            </.action>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:initialized, false)
      |> assign(:ai_model_options, [])

    {:ok, socket}
  end

  @impl true
  def update(%{ai_model_options: ai_model_options}, socket) do
    {:ok, assign(socket, :ai_model_options, ai_model_options)}
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
    |> assign_form()
    |> async_assign_ai_model_options()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_form(socket) do
    changeset =
      socket.assigns.config
      |> StudentRecordReports.change_student_record_report_ai_config()

    socket
    |> assign(:form, to_form(changeset))
  end

  defp async_assign_ai_model_options(socket) do
    ai_model_options =
      socket.assigns.config.model
      |> LantternWeb.AIHelpers.generate_ai_model_options()

    send_update(socket.assigns.myself, %{ai_model_options: ai_model_options})

    socket
  end

  # event handlers

  @impl true
  def handle_event("cancel", _, socket) do
    notify(__MODULE__, :cancel, socket.assigns)
    {:noreply, socket}
  end

  def handle_event("delete", _, socket) do
    StudentRecordReports.delete_student_record_report_ai_config(socket.assigns.config)
    |> case do
      {:ok, config} ->
        notify(__MODULE__, {:deleted, config}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("validate", %{"student_record_report_ai_config" => config_params}, socket),
    do: {:noreply, assign_validated_form(socket, config_params)}

  def handle_event("save", %{"student_record_report_ai_config" => config_params}, socket) do
    save_config(socket, socket.assigns.config.id, config_params)
  end

  defp assign_validated_form(socket, params) do
    changeset =
      socket.assigns.config
      |> StudentRecordReports.change_student_record_report_ai_config(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  defp save_config(socket, nil, config_params) do
    # inject school_id from config assign when creating new
    config_params = Map.put(config_params, "school_id", socket.assigns.config.school_id)

    StudentRecordReports.create_student_record_report_ai_config(config_params)
    |> case do
      {:ok, config} ->
        notify(__MODULE__, {:created, config}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_config(socket, _id, config_params) do
    StudentRecordReports.update_student_record_report_ai_config(
      socket.assigns.config,
      config_params
    )
    |> case do
      {:ok, config} ->
        notify(__MODULE__, {:updated, config}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
