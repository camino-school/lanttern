defmodule LantternWeb.SchoolImportLive do
  use LantternWeb, {:live_view, layout: :admin}

  alias NimbleCSV.RFC4180, as: CSV

  alias LantternWeb.SchoolsHelpers
  alias Lanttern.Schools

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Import school classes, students and teachers</h1>

    <%= render_state(assigns) %>
    """
  end

  defp render_state(%{state: "uploading"} = assigns) do
    ~H"""
    <.steps state={@state}>
      <.form id="validate-school-csv-form" for={@form} phx-submit="upload" phx-change="validate">
        <.input
          field={@form[:school_id]}
          type="select"
          label="School"
          options={@school_options}
          prompt="Select school"
        />

        <.live_file_input upload={@uploads.csv} />
        <.error :for={err <- @form[:csv].errors}>
          <%= err %>
        </.error>

        <.error :for={err <- upload_errors(@uploads.csv)}>
          <%= Phoenix.Naming.humanize(err) %>
        </.error>

        <.error :if={@csv_error}>
          <%= @csv_error %>
        </.error>

        <.button type="submit">Upload</.button>
      </.form>
    </.steps>
    """
  end

  defp render_state(%{state: "setting_up_classes"} = assigns) do
    ~H"""
    <.steps state={@state}>
      <p>We found <%= length(Map.keys(@csv_classes)) %> classes in the CSV file.</p>
      <p>
        Select the class you want to link in the dropdown, or select "Create new" to create a new class.
      </p>
      <form phx-submit="review">
        <ul class="grid grid-cols-4 gap-4">
          <li :for={{class_in_csv, class_id} <- @csv_classes} class="p-10 rounded bg-white shadow-lg">
            <%= class_in_csv %>
            <br />
            <.select
              name={class_in_csv}
              prompt="Create new class"
              options={@class_options}
              value={class_id}
            />
          </li>
        </ul>
        <.button type="submit">Continue</.button>
      </form>
    </.steps>
    """
  end

  defp render_state(%{state: "reviewing"} = assigns) do
    ~H"""
    <.steps state={@state}>
      <p>Review before importing</p>
      <table>
        <thead>
          <th>Class</th>
          <th>Student name</th>
          <th>Student email</th>
        </thead>
        <tbody>
          <tr :for={row <- @csv_rows}>
            <td>
              <%= row.class %>
              <%= if @csv_classes[row.class] == "" do %>
                <.badge>New class</.badge>
              <% end %>
            </td>
            <td><%= row.student %></td>
            <td><%= row.email %></td>
          </tr>
        </tbody>
      </table>
      <.button type="button">Import</.button>
    </.steps>
    """
  end

  defp render_state(%{state: "done"} = assigns) do
    ~H"""
    <.steps state={@state}>
      done
    </.steps>
    """
  end

  attr :state, :string, required: true
  slot :inner_block, required: true

  defp steps(assigns) do
    ~H"""
    <.step active={@state == "uploading"}>
      <:num>1</:num>
      Upload students CSV file
    </.step>
    <%= if @state == "uploading", do: render_slot(@inner_block) %>
    <.step active={@state == "setting_up_classes"}>
      <:num>2</:num>
      Setup classes
    </.step>
    <%= if @state == "setting_up_classes", do: render_slot(@inner_block) %>
    <.step active={@state == "reviewing"}>
      <:num>3</:num>
      Review
    </.step>
    <%= if @state == "reviewing", do: render_slot(@inner_block) %>
    <.step active={@state == "done"}>
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
    <div class={["flex items-center gap-4", @class]}>
      <span class={[
        "flex items-center justify-center w-8 h-8 rounded-full text-center",
        if(@active, do: "text-ltrn-white bg-ltrn-primary", else: "text-ltrn-subtle bg-ltrn-hairline")
      ]}>
        <%= render_slot(@num) %>
      </span>
      <%= render_slot(@inner_block) %>
    </div>
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
        csv_classes = process_csv_classes(csv_rows, school_id)
        class_options = SchoolsHelpers.generate_class_options(schools_ids: [school_id])

        socket =
          socket
          |> assign(:class_options, class_options)
          |> assign(:csv_classes, csv_classes)
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
      |> assign(:csv_classes, params)
      |> assign(:state, "reviewing")

    {:noreply, socket}
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
      Enum.map(csv, fn [class, student, email] ->
        %{
          class: String.trim(class),
          student: String.trim(student),
          email: String.trim(email)
        }
      end)
    }
  end

  defp format_csv({:error, error}), do: {:error, error}

  defp process_csv_classes(csv, school_id) do
    school_classes = Schools.list_classes(schools_ids: [school_id])

    csv
    |> Enum.map(& &1.class)
    |> Enum.uniq()
    |> Enum.map(&{&1, Enum.find(school_classes, fn c -> c.name == &1 end)})
    |> Enum.map(fn
      {name_in_csv, nil} -> {name_in_csv, nil}
      {name_in_csv, class} -> {name_in_csv, class.id}
    end)
    |> Enum.into(%{})
  end
end
