defmodule LantternWeb.ReportCardLive.StudentsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Personalization
  alias Lanttern.Reporting
  alias Lanttern.Reporting.StudentReportCard
  alias Lanttern.Schools

  # shared components
  alias LantternWeb.Reporting.StudentReportCardFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <div class="container mx-auto lg:max-w-5xl">
        <div class="flex items-end justify-between gap-6">
          <p class="font-display font-bold text-2xl">
            <%= gettext("Viewing") %>
            <button
              type="button"
              class="inline text-left underline hover:text-ltrn-subtle"
              phx-click={JS.exec("data-show", to: "#classes-filter-overlay")}
            >
              <%= if length(@classes) > 0 do
                @classes
                |> Enum.map(& &1.name)
                |> Enum.join(", ")
              else
                gettext("all classes")
              end %>
            </button>
          </p>
        </div>
        <div phx-update="stream" id="studends-and-report-cards">
          <div
            :for={
              {dom_id, {student, class, student_report_card}} <- @streams.students_and_report_cards
            }
            id={dom_id}
            class={[
              "flex items-center gap-4 p-4 rounded mt-4",
              if(student_report_card, do: "bg-white shadow-lg", else: "bg-ltrn-lighter")
            ]}
          >
            <div class="flex-1 flex items-center gap-4">
              <.profile_icon_with_name
                profile_name={student.name}
                theme={if student_report_card, do: "cyan", else: "subtle"}
              />
              <span :if={class && length(@classes) > 1} class="text-sm text-ltrn-subtle">
                <%= class.name %>
              </span>
            </div>
            <div class="shrink-0 flex items-center gap-2">
              <%= if student_report_card do %>
                <a
                  class={get_button_styles("ghost")}
                  href={~p"/student_report_card/#{student_report_card.id}"}
                  target="_blank"
                >
                  <%= gettext("Preview") %>
                </a>
                <.link
                  class={get_button_styles("ghost")}
                  patch={
                    ~p"/report_cards/#{@report_card}?tab=students&edit_student_report=#{student_report_card.id}"
                  }
                >
                  <%= gettext("Edit") %>
                </.link>
              <% else %>
                <.link
                  class={get_button_styles("ghost")}
                  patch={
                    ~p"/report_cards/#{@report_card}?tab=students&create_student_report=#{student.id}"
                  }
                >
                  <%= gettext("Create") %>
                </.link>
              <% end %>
            </div>
          </div>
        </div>
      </div>
      <.live_component
        module={LantternWeb.Personalization.GlobalFiltersOverlayComponent}
        id="classes-filter-overlay"
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
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> stream_configure(
        :students_and_report_cards,
        dom_id: fn
          {student, nil, nil} ->
            "student-#{student.id}"

          {student, class, nil} ->
            "student-#{student.id}-class-#{class.id}"

          {student, nil, student_report_card} ->
            "student-#{student.id}-report-card-#{student_report_card.id}"

          {student, class, student_report_card} ->
            "student-#{student.id}-class-#{class.id}-report-card-#{student_report_card.id}"
        end
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:classes, fn ->
        case Personalization.get_profile_settings(assigns.current_user.current_profile_id) do
          %{current_filters: %{classes_ids: classes_ids}} when is_list(classes_ids) ->
            Schools.list_user_classes(
              assigns.current_user,
              classes_ids: classes_ids
            )

          _ ->
            []
        end
      end)
      |> assign_new(:classes_ids, fn %{classes: classes} ->
        classes
        |> Enum.map(& &1.id)
      end)
      |> stream_students_report_cards()
      |> assign_show_student_report_card_form(assigns)

    {:ok, socket}
  end

  # use force opt to control when fetching students and report cards.
  # by default, we won't fetch if the stream already exists (to prevent
  # fetching when it's not necessary, on params change)

  defp stream_students_report_cards(socket, opts \\ [force: false])

  defp stream_students_report_cards(
         %{assigns: %{streams: %{students_and_report_cards: _}}} = socket,
         force: false
       ),
       do: socket

  defp stream_students_report_cards(socket, _) do
    students_and_report_cards =
      Reporting.list_students_for_report_card(
        socket.assigns.report_card.id,
        classes_ids: socket.assigns.classes_ids
      )

    stream(socket, :students_and_report_cards, students_and_report_cards, reset: true)
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
end
