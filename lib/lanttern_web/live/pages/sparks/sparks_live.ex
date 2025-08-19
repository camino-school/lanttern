defmodule LantternWeb.SparksLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools.Cycle
  alias Lanttern.StudentsInsights
  alias Lanttern.StudentsInsights.StudentInsight

  import LantternWeb.FiltersHelpers, only: [assign_classes_filter: 2]

  # # shared components
  # import LantternWeb.LearningContextComponents

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Sparks"))
      |> apply_assign_classes_filter()
      |> stream_students_insights()

    # |> assign(:strands_length, 0)
    # |> assign_user_filters([:subjects, :years, :starred_strands])
    # |> assign_cycle_filter(only_subcycles: true)
    # |> stream_strands()

    {:ok, socket}
  end

  defp apply_assign_classes_filter(socket) do
    assign_classes_filter_opts =
      case socket.assigns.current_user.current_profile do
        %{current_school_cycle: %Cycle{} = cycle} -> [cycles_ids: [cycle.id]]
        _ -> []
      end

    assign_classes_filter(socket, assign_classes_filter_opts)
  end

  defp stream_students_insights(socket) do
    students_insights =
      StudentsInsights.list_student_insights(socket.assigns.current_user)

    stream(socket, :students_insights, students_insights)
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    socket =
      socket
      |> assign_student_insight_and_initial_form()

    {:noreply, socket}
  end

  defp assign_student_insight_and_initial_form(%{assigns: %{live_action: :new}} = socket) do
    current_user = socket.assigns.current_user

    student_insight =
      %StudentInsight{
        author_id: current_user.current_profile.staff_member_id
      }

    changeset =
      StudentsInsights.change_student_insight(current_user, student_insight)

    socket
    |> assign(:student_insight, student_insight)
    |> assign(:form, to_form(changeset))
  end

  defp assign_student_insight_and_initial_form(socket) do
    socket
    |> assign(:student_insight, nil)
    |> assign(:form, nil)
  end

  # defp stream_strands(socket) do
  #   page =
  #     LearningContext.list_strands_page(
  #       preloads: [:subjects, :years],
  #       first: 20,
  #       after: socket.assigns[:keyset],
  #       subjects_ids: socket.assigns.selected_subjects_ids,
  #       years_ids: socket.assigns.selected_years_ids,
  #       parent_cycle_id:
  #         Map.get(socket.assigns.current_user.current_profile.current_school_cycle || %{}, :id),
  #       cycles_ids: socket.assigns.selected_cycles_ids,
  #       show_starred_for_profile_id: socket.assigns.current_user.current_profile.id,
  #       only_starred: socket.assigns.only_starred_strands
  #     )

  #   %{
  #     results: strands,
  #     keyset: keyset,
  #     has_next: has_next
  #   } = page

  #   socket
  #   |> stream(:strands, strands)
  #   |> assign(:strands_length, socket.assigns.strands_length + length(strands))
  #   |> assign(:keyset, keyset)
  #   |> assign(:has_next_page, has_next)
  # end

  # event handlers

  @impl true
  def handle_event("validate", %{"student_insight" => params}, socket),
    do: {:noreply, assign_validated_form(socket, params)}

  def handle_event("save", %{"student_insight" => params}, socket) do
    save_student_insight(socket, params)
  end

  defp assign_validated_form(socket, params) do
    changeset =
      socket.assigns.current_user
      |> StudentsInsights.change_student_insight(
        socket.assigns.student_insight,
        params
      )
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  defp save_student_insight(
         %{assigns: %{student_insight: %{id: nil}}} = socket,
         params
       ) do
    StudentsInsights.create_student_insight(socket.assigns.current_user, params)
    |> case do
      {:ok, _student_insight} ->
        socket =
          socket
          |> push_navigate(to: ~p"/sparks")
          |> put_flash(:info, gettext("Spark created successfully!"))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
