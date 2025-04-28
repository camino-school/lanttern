defmodule LantternWeb.Admin.ImportStaffMembersLive do
  use LantternWeb, {:live_view, layout: :admin}

  alias NimbleCSV.RFC4180, as: CSV

  alias Lanttern.Schools
  alias LantternWeb.SchoolsHelpers

  defp render_state(%{state: "uploading"} = assigns) do
    ~H"""
    <.steps state={@state}>
      <.form
        id="validate-school-csv-form"
        for={@form}
        phx-submit="upload"
        phx-change="validate"
        class="flex items-start gap-10"
      >
        <.input
          field={@form[:school_id]}
          type="select"
          label="Select school"
          options={@school_options}
          prompt="No school selected"
          class="flex-1"
        />

        <div class="flex-[2]">
          <div
            class="p-4 border border-dashed border-ltrn-lighter rounded-md text-center text-ltrn-subtle"
            phx-drop-target={@uploads.csv.ref}
          >
            <div>
              <.icon name="hero-arrow-up-on-square" class="h-10 w-10 mx-auto mb-6" />
              <div>
                <label
                  for={@uploads.csv.ref}
                  class="cursor-pointer text-ltrn-primary hover:text-ltrn-dark focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-ltrn-dark"
                >
                  <span>Upload a file</span>
                  <.live_file_input upload={@uploads.csv} class="sr-only" />
                </label>
                <span>or drag and drop here</span>
              </div>
            </div>

            <div
              :for={entry <- @uploads.csv.entries}
              class="flex items-center justify-center gap-2 mt-6 text-ltrn-dark"
            >
              <.icon name="hero-document" />
              <%= entry.client_name %>
            </div>
          </div>
          <%!-- <.live_file_input upload={@uploads.csv} /> --%>
          <.error :for={err <- @form[:csv].errors}>
            <%= err %>
          </.error>
          <.error :for={err <- upload_errors(@uploads.csv)}>
            <%= Phoenix.Naming.humanize(err) %>
          </.error>
          <.error :if={@csv_error}>
            <%= @csv_error %>
          </.error>
        </div>

        <.button type="submit">Upload</.button>
      </.form>
    </.steps>
    """
  end

  defp render_state(%{state: "reviewing"} = assigns) do
    ~H"""
    <.steps state={@state}>
      <p>Review before importing</p>
      <table class="w-full my-6">
        <thead class="text-left">
          <tr>
            <th class="p-2">Staff member name</th>
            <th class="p-2">Staff member email</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={row <- @csv_rows} class="border-t border-ltrn-lighter">
            <td class="p-2"><%= row.name %></td>
            <td class="p-2"><%= row.email %></td>
          </tr>
        </tbody>
      </table>
      <div class="flex items-center gap-6">
        <.button type="button" phx-click={JS.push("import", loading: "#import-loading")}>
          Import
        </.button>
        <div
          id="import-loading"
          class="hidden items-center gap-4 text-ltrn-subtle phx-click-loading:flex"
        >
          <.ping /> Processing CSV file...
        </div>
      </div>
    </.steps>
    """
  end

  defp render_state(%{state: "done"} = assigns) do
    ~H"""
    <.steps state={@state}>
      <table class="w-full my-6">
        <thead class="text-left">
          <tr>
            <th class="p-2">Staff member name</th>
            <th class="p-2">Staff member email</th>
            <th class="p-2">Status</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={{csv_row, status} <- @import_result} class="border-t border-ltrn-lighter">
            <td class="p-2"><%= csv_row.name %></td>
            <td class="p-2"><%= csv_row.email %></td>
            <td class="p-2"><.import_status status={status} /></td>
          </tr>
        </tbody>
      </table>
      <div class="flex gap-6">
        <.link href={~p"/admin"} class="underline hover:text-ltrn-subtle">Back to admin home</.link>
        <.link href={~p"/admin/import_staff_members"} class="underline hover:text-ltrn-subtle">
          Import new file
        </.link>
      </div>
    </.steps>
    """
  end

  attr :state, :string, required: true
  slot :inner_block, required: true

  defp steps(assigns) do
    ~H"""
    <.step active={@state == "uploading"} class="mt-10">
      <:num>1</:num>
      Upload students CSV file
    </.step>
    <%= if @state == "uploading", do: render_slot(@inner_block) %>
    <.step active={@state == "reviewing"} class="mt-10">
      <:num>2</:num>
      Review
    </.step>
    <%= if @state == "reviewing", do: render_slot(@inner_block) %>
    <.step active={@state == "done"} class="mt-10">
      <:num>3</:num>
      Done
    </.step>
    <%= if @state == "done", do: render_slot(@inner_block) %>
    """
  end

  attr :active, :boolean, default: false
  attr :class, :any, default: nil
  slot :num, required: true
  slot :inner_block, required: true

  defp step(assigns) do
    ~H"""
    <div class={[
      "flex items-center gap-4 mb-6 font-display",
      if(not @active, do: "text-ltrn-subtle"),
      @class
    ]}>
      <span class={[
        "flex items-center justify-center w-8 h-8 rounded-full font-black text-center",
        if(@active, do: "text-ltrn-white bg-ltrn-primary", else: "text-ltrn-subtle bg-ltrn-lighter")
      ]}>
        <%= render_slot(@num) %>
      </span>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :status, :any, required: true

  defp import_status(%{status: {:ok, _}} = assigns) do
    ~H"""
    <.badge>Success</.badge>
    """
  end

  defp import_status(%{status: {:error, _message}} = assigns) do
    ~H"""
    <.badge>Fail</.badge>
    <%= elem(@status, 1) %>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:state, "uploading")
      |> assign(:form, to_form(%{"school_id" => "", "csv" => ""}))
      |> assign(:csv_error, nil)
      |> assign(:school_options, SchoolsHelpers.generate_school_options())
      |> allow_upload(:csv, accept: ~w(.csv), max_entries: 1)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", params, socket) do
    # without this assign the school_id field is reset
    {:noreply, assign(socket, :form, to_form(params))}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl true
  def handle_event("upload", %{"school_id" => ""} = params, socket) do
    errors = [school_id: {"Can't be blank", []}]

    socket =
      socket
      |> assign(:form, to_form(params, errors: errors))

    {:noreply, socket}
  end

  def handle_event("upload", params, %{assigns: %{uploads: %{csv: %{entries: []}}}} = socket) do
    errors = [csv: "Can't be blank"]

    socket =
      socket
      |> assign(:form, to_form(params, errors: errors))

    {:noreply, socket}
  end

  def handle_event("upload", %{"school_id" => school_id}, socket) do
    case parse_upload_entry(socket, hd(socket.assigns.uploads.csv.entries)) do
      {:ok, csv_rows} ->
        socket =
          socket
          |> assign(:school_id, school_id)
          |> assign(:state, "reviewing")
          |> assign(:csv_rows, csv_rows)

        {:noreply, socket}

      {:error, error} ->
        {:noreply, assign(socket, :csv_error, error)}
    end
  end

  def handle_event("import", _params, socket) do
    case Schools.create_staff_members_from_csv(
           socket.assigns.csv_rows,
           socket.assigns.school_id
         ) do
      {:ok, import_result} ->
        socket =
          socket
          |> assign(:import_result, import_result)
          |> assign(:state, "done")

        {:noreply, socket}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  defp parse_upload_entry(socket, entry) do
    consume_uploaded_entry(socket, entry, fn %{path: path} ->
      {:ok,
       File.read!(path)
       |> CSV.parse_string()
       |> validate_csv()
       |> format_csv()}
    end)
  end

  defp validate_csv(csv) do
    cond do
      csv == [] ->
        {:error, "No entries in CSV"}

      csv |> hd() |> length() != 2 ->
        {:error,
         "Expected 2 columns (staff member name and email), but got #{csv |> hd() |> length()}"}

      true ->
        {:ok, csv}
    end
  end

  defp format_csv({:ok, csv}) do
    {
      :ok,
      Enum.map(csv, fn [name, email] ->
        %{
          name: String.trim(name),
          email: String.trim(email)
        }
      end)
    }
  end

  defp format_csv({:error, error}), do: {:error, error}
end
