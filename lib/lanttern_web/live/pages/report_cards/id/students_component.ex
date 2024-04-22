defmodule LantternWeb.ReportCardLive.StudentsComponent do
  use LantternWeb, :live_component

  alias Phoenix.LiveView.LiveStream

  alias Lanttern.Reporting
  alias Lanttern.Reporting.StudentReportCard
  alias Lanttern.Schools
  alias Lanttern.Schools.Student

  import LantternWeb.PersonalizationHelpers, only: [assign_user_filters: 3]

  # shared components
  alias LantternWeb.Reporting.StudentReportCardFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pt-10 pb-20">
      <.responsive_container>
        <div :if={@has_students_in_report_card} class="mb-10">
          <p class="font-display font-bold text-2xl">
            <%= gettext("Students linked to this report card") %>
          </p>
          <div phx-update="stream" id="other-students-and-report-cards">
            <.student_and_report_card_row
              :for={{dom_id, {student, student_report_card}} <- @streams.students_in_report_card}
              id={dom_id}
              report_card_id={@report_card.id}
              student={student}
              student_report_card={student_report_card}
            />
          </div>
        </div>
        <%= if @selected_classes != [] do %>
          <p class="font-display font-bold text-2xl">
            <%= gettext("Link students from") %>
            <button
              type="button"
              class="inline text-left underline hover:text-ltrn-subtle"
              phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
            >
              <%= @selected_classes
              |> Enum.map(& &1.name)
              |> Enum.join(", ") %>
            </button>
            <%= gettext("to this report card") %>
          </p>
        <% else %>
          <p class="font-display font-bold text-2xl">
            <button
              type="button"
              class="underline hover:text-ltrn-subtle"
              phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
            >
              <%= gettext("Select a class") %>
            </button>
            <%= gettext("to view students assessments") %>
          </p>
        <% end %>
        <.other_students_list
          has_selected_class={@selected_classes_ids != []}
          has_other_students={@has_other_students}
          students_stream={@streams.other_students}
          report_card_id={@report_card.id}
          myself={@myself}
        />
      </.responsive_container>
      <.live_component
        module={LantternWeb.Personalization.FiltersOverlayComponent}
        id="classes-filter-modal"
        current_user={@current_user}
        title={gettext("Select classes")}
        filter_type={:classes}
        navigate={~p"/report_cards/#{@report_card}"}
      />
      <.slide_over
        :if={@show_student_report_card_form}
        id="student-report-card-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/report_cards/#{@report_card}?tab=students")}
      >
        <:title><%= @form_overlay_title %></:title>
        <.metadata class="mb-4" icon_name="hero-document-text">
          <%= @report_card.name %>
        </.metadata>
        <.metadata class="mb-4" icon_name="hero-user">
          <%= @student.name %>
        </.metadata>
        <.live_component
          module={StudentReportCardFormComponent}
          id={@student_report_card.id || :new}
          student_report_card={@student_report_card}
          navigate={~p"/report_cards/#{@report_card}?tab=students"}
          hide_submit
        />
        <:actions_left :if={@student_report_card.id}>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete_student_report_card"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#student-report-card-form-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="student-report-card-form">
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
      <.fixed_bar :if={@selected_students_ids != []} class="flex items-center gap-6">
        <p class="flex-1 text-sm text-white">
          <%= ngettext(
            "1 student selected",
            "%{count} students selected",
            length(@selected_students_ids)
          ) %>
        </p>
        <.button
          phx-click={
            JS.push("clear_student_selection", target: @myself)
            |> JS.remove_class("outline outline-4 outline-ltrn-dark",
              to: "#students-and-report-cards > div"
            )
          }
          theme="ghost"
        >
          <%= gettext("Clear selection") %>
        </.button>
        <.button type="button" phx-click="batch_create_student_report_card" phx-target={@myself}>
          <%= gettext("Create for selected") %>
        </.button>
      </.fixed_bar>
    </div>
    """
  end

  attr :has_selected_class, :boolean, required: true
  attr :has_other_students, :boolean, required: true
  attr :students_stream, LiveStream, required: true
  attr :report_card_id, :integer, required: true
  attr :myself, :any, required: true

  def other_students_list(%{has_selected_class: false} = assigns) do
    ~H"""
    <div class="p-10 mt-4 rounded shadow-xl bg-white">
      <.empty_state><%= gettext("No results") %></.empty_state>
    </div>
    """
  end

  def other_students_list(%{has_other_students: false} = assigns) do
    ~H"""
    <div class="p-10 mt-4 rounded shadow-xl bg-white">
      <.empty_state>
        <%= gettext("All students from selected classes are already linked to this report card") %>
      </.empty_state>
    </div>
    """
  end

  def other_students_list(assigns) do
    ~H"""
    <div phx-update="stream" id="students-and-report-cards">
      <.student_and_report_card_row
        :for={{dom_id, student} <- @students_stream}
        id={dom_id}
        report_card_id={@report_card_id}
        student={student}
        student_report_card={nil}
        on_click={
          JS.push("toggle_student_id", value: %{"student_id" => student.id}, target: @myself)
          |> JS.toggle_class("outline outline-4 outline-ltrn-dark", to: "##{dom_id}")
        }
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :report_card_id, :string, required: true
  attr :student, Student, required: true
  attr :student_report_card, :any, required: true
  attr :on_click, JS, default: nil

  def student_and_report_card_row(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "flex items-center gap-4 p-4 rounded mt-4",
        if(@student_report_card, do: "bg-white shadow-lg", else: "bg-ltrn-lighter")
      ]}
    >
      <div class="flex-1 flex items-center gap-4">
        <.profile_icon_with_name
          theme={if @student_report_card, do: "cyan", else: "subtle"}
          profile_name={@student.name}
          extra_info={@student.classes |> Enum.map(& &1.name) |> Enum.join(", ")}
          on_click={@on_click}
        />
      </div>
      <div class="shrink-0 flex items-center gap-2">
        <%= if @student_report_card do %>
          <a
            class={get_button_styles("ghost")}
            href={~p"/student_report_card/#{@student_report_card.id}"}
            target="_blank"
          >
            <%= gettext("Preview") %>
          </a>
          <.link
            class={get_button_styles("ghost")}
            patch={
              ~p"/report_cards/#{@report_card_id}?tab=students&edit_student_report=#{@student_report_card.id}"
            }
          >
            <%= gettext("Edit") %>
          </.link>
        <% else %>
          <.link
            class={get_button_styles("ghost")}
            patch={
              ~p"/report_cards/#{@report_card_id}?tab=students&create_student_report=#{@student.id}"
            }
          >
            <%= gettext("Create") %>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> stream_configure(
        :students_in_report_card,
        dom_id: fn {student, _} -> "student-#{student.id}" end
      )
      |> assign(:selected_students_ids, [])

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_user_filters([:classes], assigns.current_user)
      |> stream_students_report_cards()
      |> assign_show_student_report_card_form(assigns)

    {:ok, socket}
  end

  # use force opt to control when fetching students and report cards.
  # by default, we won't fetch if the stream already exists (to prevent
  # fetching when it's not necessary, on params change)

  defp stream_students_report_cards(socket, opts \\ [force: false])

  defp stream_students_report_cards(
         %{assigns: %{streams: %{students_in_report_card: _}}} = socket,
         force: false
       ),
       do: socket

  defp stream_students_report_cards(socket, _) do
    students_in_report_card =
      Reporting.list_students_for_report_card(
        socket.assigns.report_card.id,
        only_with_report: true
      )

    has_students_in_report_card = length(students_in_report_card) > 0

    # list students for current classes filters,
    # and remove the ones already in `students_in_report_card`

    students_ids =
      students_in_report_card
      |> Enum.map(fn {student, _} -> student.id end)

    other_students =
      Schools.list_students(classes_ids: socket.assigns.selected_classes_ids)
      |> Enum.filter(&(&1.id not in students_ids))

    has_other_students = length(other_students) > 0

    socket
    |> stream(:students_in_report_card, students_in_report_card, reset: true)
    |> assign(:has_students_in_report_card, has_students_in_report_card)
    |> stream(:other_students, other_students, reset: true)
    |> assign(:has_other_students, has_other_students)
  end

  defp assign_show_student_report_card_form(socket, %{
         params: %{"create_student_report" => student_id}
       }) do
    cond do
      String.match?(student_id, ~r/[0-9]+/) ->
        case Schools.get_student(student_id) do
          nil ->
            # student does not exist, just return socket
            assign(socket, :show_student_report_card_form, false)

          student ->
            socket
            |> assign(:student_report_card, %StudentReportCard{
              report_card_id: socket.assigns.report_card.id,
              student_id: student_id
            })
            |> assign(:student, student)
            |> assign(:form_overlay_title, gettext("Create student report card"))
            |> assign(:show_student_report_card_form, true)
        end

      true ->
        assign(socket, :show_student_report_card_form, false)
    end
  end

  defp assign_show_student_report_card_form(socket, %{
         params: %{"edit_student_report" => id}
       }) do
    report_card_id = socket.assigns.report_card.id

    cond do
      String.match?(id, ~r/[0-9]+/) ->
        case Reporting.get_student_report_card(id) do
          %StudentReportCard{report_card_id: ^report_card_id} = student_report_card ->
            socket
            |> assign(:form_overlay_title, gettext("Edit student report card"))
            |> assign(:student_report_card, student_report_card)
            |> assign(:student, Schools.get_student(student_report_card.student_id))
            |> assign(:show_student_report_card_form, true)

          _ ->
            assign(socket, :show_student_report_card_form, false)
        end

      true ->
        assign(socket, :show_student_report_card_form, false)
    end
  end

  defp assign_show_student_report_card_form(socket, _),
    do: assign(socket, :show_student_report_card_form, false)

  @impl true
  def handle_event("toggle_student_id", %{"student_id" => id}, socket) do
    selected_students_ids =
      case id in socket.assigns.selected_students_ids do
        true ->
          socket.assigns.selected_students_ids
          |> Enum.filter(&(&1 != id))

        false ->
          [id | socket.assigns.selected_students_ids]
      end

    {:noreply, assign(socket, :selected_students_ids, selected_students_ids)}
  end

  def handle_event("clear_student_selection", _params, socket) do
    {:noreply, assign(socket, :selected_students_ids, [])}
  end

  def handle_event("batch_create_student_report_card", _params, socket) do
    report_card_id = socket.assigns.report_card.id
    students_ids = socket.assigns.selected_students_ids

    {:ok, results} = batch_create_student_report_card(report_card_id, students_ids)

    socket =
      socket
      |> put_flash(:info, build_batch_create_student_report_card_message(results))
      |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}?tab=students")

    {:noreply, socket}
  end

  def handle_event("delete_student_report_card", _params, socket) do
    case Reporting.delete_student_report_card(socket.assigns.student_report_card) do
      {:ok, _student_report_card} ->
        socket =
          socket
          |> put_flash(:info, gettext("Student report card deleted"))
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}?tab=students")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Error deleting student report card"))

        {:noreply, socket}
    end
  end

  # helpers

  defp batch_create_student_report_card(
         report_card_id,
         students_ids,
         results \\ %{created: 0, skipped: 0, error: 0}
       )

  defp batch_create_student_report_card(_, [], results), do: {:ok, results}

  defp batch_create_student_report_card(report_card_id, [student_id | students_ids], results) do
    student_report_card =
      Reporting.get_student_report_card_by_student_and_parent_report(student_id, report_card_id)

    params = %{report_card_id: report_card_id, student_id: student_id}

    case student_report_card do
      nil ->
        case Reporting.create_student_report_card(params) do
          {:ok, _} ->
            batch_create_student_report_card(
              report_card_id,
              students_ids,
              Map.update!(results, :created, &(&1 + 1))
            )

          {:error, _} ->
            batch_create_student_report_card(
              report_card_id,
              students_ids,
              Map.update!(results, :error, &(&1 + 1))
            )
        end

      %StudentReportCard{} ->
        batch_create_student_report_card(
          report_card_id,
          students_ids,
          Map.update!(results, :skipped, &(&1 + 1))
        )
    end
  end

  defp build_batch_create_student_report_card_message(%{} = results),
    do: build_batch_create_student_report_card_message(Enum.map(results, & &1), [])

  defp build_batch_create_student_report_card_message([], msgs),
    do: Enum.join(msgs, ", ")

  defp build_batch_create_student_report_card_message([{_operation, 0} | results], msgs),
    do: build_batch_create_student_report_card_message(results, msgs)

  defp build_batch_create_student_report_card_message([{:created, count} | results], msgs) do
    msg =
      ngettext("1 student report card created", "%{count} students report cards created", count)

    build_batch_create_student_report_card_message(results, [msg | msgs])
  end

  defp build_batch_create_student_report_card_message([{:skipped, count} | results], msgs) do
    msg = ngettext("1 student skipped", "%{count} students skipped", count)
    build_batch_create_student_report_card_message(results, [msg | msgs])
  end

  defp build_batch_create_student_report_card_message([{:error, count} | results], msgs) do
    msg = ngettext("1 report creation failed", "%{count} reports creation failed", count)
    build_batch_create_student_report_card_message(results, [msg | msgs])
  end
end
