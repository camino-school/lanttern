defmodule LantternWeb.ReportCardLive.StudentsComponent do
  use LantternWeb, :live_component

  alias Phoenix.LiveView.LiveStream

  alias Lanttern.Reporting
  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Reporting.StudentReportCard
  alias Lanttern.Schools
  alias Lanttern.Schools.Student

  import LantternWeb.FiltersHelpers,
    only: [save_profile_filters: 3, assign_report_card_linked_student_classes_filter: 2]

  # shared components
  alias LantternWeb.Reporting.StudentReportCardFormComponent
  alias LantternWeb.Filters.InlineFiltersComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pt-10 pb-20">
      <.responsive_container>
        <div class="mb-10">
          <p class="font-display font-bold text-2xl">
            <%= gettext("Students linked to this report card") %>
          </p>
          <.live_component
            module={InlineFiltersComponent}
            id="linked-students-classes-filter"
            filter_items={@linked_students_classes}
            selected_items_ids={@selected_linked_students_classes_ids}
            class="mt-4"
            notify_component={@myself}
          />
          <%= if @has_students_in_report_card do %>
            <div phx-update="stream" id="students-and-report-cards">
              <.student_and_report_card_row
                :for={{dom_id, {student, student_report_card}} <- @streams.students_in_report_card}
                id={dom_id}
                report_card_id={@report_card.id}
                student={student}
                student_report_card={student_report_card}
                disable_on_click={@selected_students_ids != []}
                on_click={
                  JS.push("toggle_student_report_card_id",
                    value: %{"student_report_card_id" => student_report_card.id},
                    target: @myself
                  )
                  |> JS.toggle_class("outline outline-4 outline-ltrn-dark", to: "##{dom_id}")
                }
              />
            </div>
          <% else %>
            <div class="p-10 mt-4 rounded shadow-xl bg-white">
              <.empty_state>
                <%= gettext("No students linked to this report card yet") %>
              </.empty_state>
            </div>
          <% end %>
        </div>
        <p class="font-display font-bold text-2xl">
          <%= case @report_card.school_cycle.parent_cycle do
            %{name: parent_cycle_name} ->
              gettext("Link students from %{year} (%{cycle}) to this report card",
                year: @report_card.year.name,
                cycle: parent_cycle_name
              )

            _ ->
              gettext("Link students from %{year} to this report card",
                year: @report_card.year.name
              )
          end %>
        </p>
        <.other_students_list
          has_other_students={@has_other_students}
          students_stream={@streams.other_students}
          report_card={@report_card}
          myself={@myself}
        />
      </.responsive_container>
      <.slide_over
        :if={@show_student_report_card_form}
        id="student-report-card-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/report_cards/#{@report_card}/students")}
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
          navigate={~p"/report_cards/#{@report_card}/students"}
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
      <.fixed_bar :if={@selected_students_report_cards_ids != []} class="flex items-center gap-6">
        <p class="flex-1 text-sm text-white">
          <%= ngettext(
            "1 student report card selected",
            "%{count} students report cards selected",
            length(@selected_students_report_cards_ids)
          ) %>
        </p>
        <div class="flex items-center gap-2">
          <span class="text-sm text-white"><%= gettext("Student access") %></span>
          <div class="group relative">
            <.icon_button
              type="button"
              name="hero-lock-closed"
              theme="ghost"
              rounded
              sr_text={gettext("Remove access from students")}
              phx-click={
                JS.push(
                  "batch_update_student_report_card",
                  value: %{"attrs" => %{"allow_student_access" => false}},
                  target: @myself
                )
              }
            />
            <.tooltip h_pos="center"><%= gettext("Remove access") %></.tooltip>
          </div>
          <div class="group relative">
            <.icon_button
              type="button"
              name="hero-lock-open"
              rounded
              sr_text={gettext("Give access to students")}
              phx-click={
                JS.push(
                  "batch_update_student_report_card",
                  value: %{"attrs" => %{"allow_student_access" => true}},
                  target: @myself
                )
              }
            />
            <.tooltip h_pos="center"><%= gettext("Allow access") %></.tooltip>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <span class="text-sm text-white"><%= gettext("Guardian access") %></span>
          <div class="group relative">
            <.icon_button
              type="button"
              name="hero-lock-closed"
              theme="ghost"
              rounded
              sr_text={gettext("Remove access from guardians")}
              phx-click={
                JS.push(
                  "batch_update_student_report_card",
                  value: %{"attrs" => %{"allow_guardian_access" => false}},
                  target: @myself
                )
              }
            />
            <.tooltip h_pos="center"><%= gettext("Remove access") %></.tooltip>
          </div>
          <div class="group relative">
            <.icon_button
              type="button"
              name="hero-lock-open"
              rounded
              sr_text={gettext("Give access to guardians")}
              phx-click={
                JS.push(
                  "batch_update_student_report_card",
                  value: %{"attrs" => %{"allow_guardian_access" => true}},
                  target: @myself
                )
              }
            />
            <.tooltip h_pos="right"><%= gettext("Allow access") %></.tooltip>
          </div>
        </div>
      </.fixed_bar>
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
              to: "#students-without-report-cards > div"
            )
          }
          theme="ghost"
        >
          <%= gettext("Clear selection") %>
        </.button>
        <.button type="button" phx-click="batch_create_student_report_card" phx-target={@myself}>
          <%= gettext("Link selected") %>
        </.button>
      </.fixed_bar>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :report_card_id, :string, required: true
  attr :student, Student, required: true
  attr :student_report_card, StudentReportCard, required: true
  attr :disable_on_click, :boolean, required: true
  attr :on_click, JS, required: true

  def student_and_report_card_row(assigns) do
    ~H"""
    <div id={@id} class="flex items-center gap-4 p-4 rounded mt-4 bg-white shadow-lg">
      <div class="flex-1 flex items-center gap-4">
        <.profile_icon_with_name
          theme="cyan"
          profile_name={@student.name}
          extra_info={@student.classes |> Enum.map(& &1.name) |> Enum.join(", ")}
          on_click={@on_click}
        />
      </div>
      <div class="shrink-0 flex items-center gap-2">
        <div
          :if={@student_report_card.comment}
          class="group relative flex items-center justify-center w-10 h-10 rounded-full bg-ltrn-diff-lightest"
        >
          <.icon name="hero-chat-bubble-oval-left-mini" class="w-5 h-5 text-ltrn-diff-dark" />
          <.tooltip h_pos="center">
            <%= gettext("Has comments") %>
          </.tooltip>
        </div>
        <div
          :if={@student_report_card.footnote}
          class="group relative flex items-center justify-center w-10 h-10 rounded-full bg-ltrn-diff-lightest"
        >
          <.icon name="hero-document-text-mini" class="w-5 h-5 text-ltrn-diff-dark" />
          <.tooltip h_pos="center">
            <%= gettext("Has footnote") %>
          </.tooltip>
        </div>
        <.access_status
          has_access={@student_report_card.allow_student_access}
          icon_name="hero-user-mini"
          with_access_text={gettext("Shared with student")}
          without_access_text={gettext("Not shared with student")}
        />
        <.access_status
          has_access={@student_report_card.allow_guardian_access}
          icon_name="hero-users-mini"
          with_access_text={gettext("Shared with guardians")}
          without_access_text={gettext("Not shared with guardians")}
        />
        <div class="group relative">
          <a
            class={get_button_styles("ghost")}
            href={~p"/student_report_card/#{@student_report_card.id}"}
            target="_blank"
            data-test-id="preview-button"
          >
            <.icon name="hero-eye-mini" class="w-5 h-5" />
          </a>
          <.tooltip h_pos="center"><%= gettext("Preview") %></.tooltip>
        </div>
        <div class="group relative">
          <.link
            class={get_button_styles("ghost")}
            patch={
              ~p"/report_cards/#{@report_card_id}/students?edit_student_report=#{@student_report_card.id}"
            }
          >
            <.icon name="hero-pencil-mini" class="w-5 h-5" />
          </.link>
          <.tooltip h_pos="center"><%= gettext("Edit") %></.tooltip>
        </div>
      </div>
    </div>
    """
  end

  attr :has_access, :boolean, required: true
  attr :icon_name, :string, required: true
  attr :with_access_text, :string, required: true
  attr :without_access_text, :string, required: true

  def access_status(assigns) do
    ~H"""
    <div class={[
      "group relative flex items-center justify-center w-10 h-10 rounded-full",
      if(@has_access, do: "bg-ltrn-mesh-primary", else: "bg-ltrn-lightest")
    ]}>
      <.icon
        name={@icon_name}
        class={[
          "w-5 h-5",
          if(@has_access, do: "text-ltrn-dark", else: "text-ltrn-subtle")
        ]}
      />
      <.icon
        :if={@has_access}
        name="hero-check-circle-mini"
        class="absolute -top-1 -right-1 text-ltrn-primary"
      />
      <.tooltip h_pos="center">
        <%= if @has_access, do: @with_access_text, else: @without_access_text %>
      </.tooltip>
    </div>
    """
  end

  attr :has_other_students, :boolean, required: true
  attr :students_stream, LiveStream, required: true
  attr :report_card, ReportCard, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true

  def other_students_list(%{has_other_students: false} = assigns) do
    ~H"""
    <div class="p-10 mt-4 rounded shadow-xl bg-white">
      <.empty_state>
        <%= case @report_card.school_cycle.parent_cycle do
          %{name: parent_cycle_name} ->
            gettext(
              "All students from %{year} (%{cycle}) classes are already linked to this report card",
              year: @report_card.year.name,
              cycle: parent_cycle_name
            )

          _ ->
            gettext("All students from %{year} classes are already linked to this report card",
              year: @report_card.year.name
            )
        end %>
      </.empty_state>
    </div>
    """
  end

  def other_students_list(assigns) do
    ~H"""
    <div phx-update="stream" id="students-without-report-cards">
      <.student_row
        :for={{dom_id, student} <- @students_stream}
        id={dom_id}
        report_card_id={@report_card.id}
        student={student}
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
  attr :on_click, JS, default: nil

  def student_row(assigns) do
    ~H"""
    <div id={@id} class="flex items-center gap-4 p-4 rounded mt-4 bg-ltrn-lighter">
      <div class="flex-1 flex items-center gap-4">
        <.profile_icon_with_name
          theme="subtle"
          profile_name={@student.name}
          extra_info={@student.classes |> Enum.map(& &1.name) |> Enum.join(", ")}
          on_click={@on_click}
        />
      </div>
      <div class="shrink-0 flex items-center gap-2">
        <.link
          class={get_button_styles("ghost")}
          patch={~p"/report_cards/#{@report_card_id}/students?create_student_report=#{@student.id}"}
        >
          <%= gettext("Link") %>
        </.link>
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
      |> assign(:selected_students_report_cards_ids, [])
      |> assign(:selected_linked_students_classes_ids, [])
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {InlineFiltersComponent, {:apply, classes_ids}}}, socket) do
    socket =
      socket
      |> assign(:selected_linked_students_classes_ids, classes_ids)
      |> save_profile_filters(
        [:linked_students_classes],
        report_card_id: socket.assigns.report_card.id
      )
      |> stream_students_report_cards()

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_student_report_card()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_report_card_linked_student_classes_filter(socket.assigns.report_card)
    |> stream_students_report_cards()
    |> stream_students_not_linked_to_report_card()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_students_report_cards(socket) do
    students_in_report_card =
      Reporting.list_students_linked_to_report_card(
        socket.assigns.report_card,
        classes_ids: socket.assigns.selected_linked_students_classes_ids
      )

    has_students_in_report_card = length(students_in_report_card) > 0

    # remove selected reports if needed
    students_report_cards_ids =
      students_in_report_card
      |> Enum.map(fn {_, src} -> src.id end)

    selected_students_report_cards_ids =
      socket.assigns.selected_students_report_cards_ids
      |> Enum.filter(&(&1 in students_report_cards_ids))

    socket
    |> stream(:students_in_report_card, students_in_report_card, reset: true)
    |> assign(:has_students_in_report_card, has_students_in_report_card)
    |> assign(:selected_students_report_cards_ids, selected_students_report_cards_ids)
  end

  defp stream_students_not_linked_to_report_card(socket) do
    other_students =
      Reporting.list_students_not_linked_to_report_card(socket.assigns.report_card)

    has_other_students = length(other_students) > 0

    socket
    |> stream(:other_students, other_students, reset: true)
    |> assign(:has_other_students, has_other_students)
  end

  defp assign_student_report_card(
         %{
           assigns: %{
             params: %{"create_student_report" => student_id}
           }
         } = socket
       ) do
    if String.match?(student_id, ~r/[0-9]+/) do
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
    else
      assign(socket, :show_student_report_card_form, false)
    end
  end

  defp assign_student_report_card(
         %{
           assigns: %{
             params: %{"edit_student_report" => id}
           }
         } = socket
       ) do
    report_card_id = socket.assigns.report_card.id

    if String.match?(id, ~r/[0-9]+/) do
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
    else
      assign(socket, :show_student_report_card_form, false)
    end
  end

  defp assign_student_report_card(socket),
    do: assign(socket, :show_student_report_card_form, false)

  @impl true
  def handle_event("toggle_student_report_card_id", %{"student_report_card_id" => id}, socket) do
    selected_students_report_cards_ids =
      case id in socket.assigns.selected_students_report_cards_ids do
        true ->
          socket.assigns.selected_students_report_cards_ids
          |> Enum.filter(&(&1 != id))

        false ->
          [id | socket.assigns.selected_students_report_cards_ids]
      end

    {:noreply,
     assign(socket, :selected_students_report_cards_ids, selected_students_report_cards_ids)}
  end

  def handle_event("batch_update_student_report_card", %{"attrs" => attrs}, socket) do
    selected_students_report_cards =
      Reporting.list_student_report_cards(ids: socket.assigns.selected_students_report_cards_ids)

    socket =
      case Reporting.batch_update_student_report_card(selected_students_report_cards, attrs) do
        {:ok, _} ->
          socket
          |> put_flash(:info, gettext("Students report cards access updated"))
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}/students")

        {:error, _, _, _} ->
          socket
          |> put_flash(:error, gettext("Something got wrong"))
      end

    {:noreply, socket}
  end

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
      |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}/students")

    {:noreply, socket}
  end

  def handle_event("delete_student_report_card", _params, socket) do
    case Reporting.delete_student_report_card(socket.assigns.student_report_card) do
      {:ok, _student_report_card} ->
        socket =
          socket
          |> put_flash(:info, gettext("Student report card deleted"))
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}/students")

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
