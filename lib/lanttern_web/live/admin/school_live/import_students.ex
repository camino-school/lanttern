defmodule LantternWeb.Admin.SchoolLive.ImportStudents do
  use LantternWeb, {:live_view, layout: :admin}

  alias NimbleCSV.RFC4180, as: CSV

  alias LantternWeb.SchoolsHelpers
  alias Lanttern.Schools

  # function components

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

  defp render_state(%{state: "setting_up_classes"} = assigns) do
    ~H"""
    <.steps state={@state}>
      <p class="mb-4">
        We found <%= length(Map.keys(@csv_class_name_id_map)) %> classes in the CSV file.
      </p>
      <p class="mb-4">
        Select the class you want to link in the dropdown, or select "Create new" to create a new class.
      </p>
      <form phx-submit="review">
        <div class="grid grid-cols-3 gap-10 mb-6">
          <div
            :for={{class_in_csv, class_id} <- @csv_class_name_id_map}
            class="p-6 rounded bg-white shadow-lg"
          >
            <p class="flex items-center gap-4 mb-6">
              <%= class_in_csv %>
              <%= if class_id != nil do %>
                <.badge>Existing class</.badge>
              <% end %>
            </p>
            <.select
              name={class_in_csv}
              prompt="Create new class"
              options={@class_options}
              value={class_id}
              disabled={class_id != nil}
            />
            <%= if class_id != nil do %>
              <input type="hidden" name={class_in_csv} value={class_id} />
            <% end %>
          </div>
        </div>
        <.button type="submit">Continue</.button>
      </form>
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
            <th class="p-2">Class</th>
            <th class="p-2">Student name</th>
            <th class="p-2">Student email</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={row <- @csv_rows} class="border-t border-ltrn-lighter">
            <td class="p-2">
              <.class_in_table
                csv_class_id={@csv_class_name_id_map[row.class_name]}
                csv_class_name={row.class_name}
                school_classes={@school_classes}
              />
            </td>
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
            <th class="p-2">Class</th>
            <th class="p-2">Student name</th>
            <th class="p-2">Student email</th>
            <th class="p-2">Status</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={{csv_row, status} <- @import_result} class="border-t border-ltrn-lighter">
            <td class="p-2">
              <.class_in_table
                csv_class_id={@csv_class_name_id_map[csv_row.class_name]}
                csv_class_name={csv_row.class_name}
                school_classes={@school_classes}
              />
            </td>
            <td class="p-2"><%= csv_row.name %></td>
            <td class="p-2"><%= csv_row.email %></td>
            <td class="p-2"><.import_status status={status} /></td>
          </tr>
        </tbody>
      </table>
      <div class="flex gap-6">
        <.link href={~p"/admin"} class="underline hover:text-ltrn-subtle">Back to admin home</.link>
        <.link href={~p"/admin/import_students"} class="underline hover:text-ltrn-subtle">
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
    <.step active={@state == "setting_up_classes"} class="mt-10">
      <:num>2</:num>
      Setup classes
    </.step>
    <%= if @state == "setting_up_classes", do: render_slot(@inner_block) %>
    <.step active={@state == "reviewing"} class="mt-10">
      <:num>3</:num>
      Review
    </.step>
    <%= if @state == "reviewing", do: render_slot(@inner_block) %>
    <.step active={@state == "done"} class="mt-10">
      <:num>4</:num>
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

  attr :csv_class_id, :string, required: true
  attr :csv_class_name, :string, default: ""
  attr :school_classes, :list, required: true

  defp class_in_table(%{csv_class_id: ""} = assigns) do
    ~H"""
    <%= @csv_class_name %>
    <.badge>New class</.badge>
    """
  end

  defp class_in_table(%{csv_class_id: csv_class_id, school_classes: school_classes} = assigns) do
    assigns =
      assign(
        assigns,
        :class_name,
        school_classes
        |> Enum.find(&("#{&1.id}" == csv_class_id))
        |> Map.get(:name)
      )

    ~H"""
    <%= @class_name %>
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

  # lifecycle

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

  # event handlers

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
        school_classes = Schools.list_classes(schools_ids: [school_id])
        csv_class_name_id_map = process_csv_classes(csv_rows, school_classes)
        class_options = SchoolsHelpers.generate_class_options(schools_ids: [school_id])

        socket =
          socket
          |> assign(:school_id, school_id)
          |> assign(:school_classes, school_classes)
          |> assign(:class_options, class_options)
          |> assign(:csv_class_name_id_map, csv_class_name_id_map)
          |> assign(:state, "setting_up_classes")
          |> assign(:csv_rows, csv_rows)

        {:noreply, socket}

      {:error, error} ->
        {:noreply, assign(socket, :csv_error, error)}
    end
  end

  def handle_event("review", params, socket) do
    socket =
      socket
      |> assign(:csv_class_name_id_map, params)
      |> assign(:state, "reviewing")

    {:noreply, socket}
  end

  def handle_event("import", _params, socket) do
    case Schools.create_students_from_csv(
           socket.assigns.csv_rows,
           socket.assigns.csv_class_name_id_map,
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
      length(csv) == 0 ->
        {:error, "No entries in CSV"}

      csv |> hd() |> length() != 3 ->
        {:error,
         "Expected 3 columns (class name, student name, and student email), but got #{csv |> hd() |> length()}"}

      true ->
        {:ok, csv}
    end
  end

  defp format_csv({:ok, csv}) do
    {
      :ok,
      Enum.map(csv, fn [class_name, name, email] ->
        %{
          class_name: String.trim(class_name),
          name: String.trim(name),
          email: String.trim(email)
        }
      end)
    }
  end

  defp format_csv({:error, error}), do: {:error, error}

  defp process_csv_classes(csv, school_classes) do
    csv
    |> Enum.map(& &1.class_name)
    |> Enum.uniq()
    |> Enum.map(&{&1, Enum.find(school_classes, fn c -> c.name == &1 end)})
    |> Enum.map(fn
      {name_in_csv, nil} -> {name_in_csv, nil}
      {name_in_csv, class} -> {name_in_csv, class.id}
    end)
    |> Enum.into(%{})
  end
end
