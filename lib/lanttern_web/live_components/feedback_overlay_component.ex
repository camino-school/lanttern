defmodule LantternWeb.FeedbackOverlayComponent do
  @moduledoc """
  Expected external assigns:

  ```elixir
  attr :assessment_point_id, :string, required: true
  attr :student_id, :string, required: true
  attr :on_cancel, JS, default: %JS{}
  ```

  """
  use LantternWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.slide_over :if={@show} id={@id} show={@show} on_cancel={Map.get(assigns, :on_cancel, %JS{})}>
        <:title>Feedback</:title>
        TBD
      </.slide_over>
    </div>
    """
  end

  # lifecycle

  # def mount(socket) do
  #   changeset = Assessments.new_assessment_point_changeset()

  #   scale_options = GradingHelpers.generate_scale_options()
  #   class_options = SchoolsHelpers.generate_class_options()
  #   selected_classes = []
  #   student_options = SchoolsHelpers.generate_student_options()
  #   selected_students = []

  #   socket =
  #     socket
  #     |> assign(%{
  #       form: to_form(changeset),
  #       scale_options: scale_options,
  #       class_options: class_options,
  #       selected_classes: selected_classes,
  #       student_options: student_options,
  #       selected_students: selected_students
  #     })

  #   {:ok, socket}
  # end

  # # event handlers

  # def handle_event(
  #       "class_selected",
  #       %{"assessment_point" => %{"class_id" => class_id}},
  #       socket
  #     )
  #     when class_id != "" do
  #   class_id = String.to_integer(class_id)

  #   selected_class =
  #     extract_from_options(
  #       socket.assigns.class_options,
  #       class_id
  #     )

  #   class_students =
  #     Schools.list_students(classes_ids: [class_id])
  #     |> Enum.map(fn s -> {:"#{s.name}", s.id} end)

  #   socket =
  #     socket
  #     |> update(:selected_classes, &merge_with_selected(&1, selected_class))
  #     |> update(:selected_students, &merge_with_selected(&1, class_students))

  #   {:noreply, socket}
  # end

  # def handle_event("class_removed", %{"id" => class_id}, socket) do
  #   class_id = String.to_integer(class_id)

  #   socket =
  #     socket
  #     |> update(:selected_classes, &remove_from_selected(&1, class_id))

  #   {:noreply, socket}
  # end

  # def handle_event(
  #       "student_selected",
  #       %{"assessment_point" => %{"student_id" => student_id}},
  #       socket
  #     )
  #     when student_id != "" do
  #   student_id = String.to_integer(student_id)

  #   selected_student =
  #     extract_from_options(
  #       socket.assigns.student_options,
  #       student_id
  #     )

  #   socket =
  #     socket
  #     |> update(:selected_students, &merge_with_selected(&1, selected_student))

  #   {:noreply, socket}
  # end

  # def handle_event("student_removed", %{"id" => student_id}, socket) do
  #   student_id = String.to_integer(student_id)

  #   socket =
  #     socket
  #     |> update(:selected_students, &remove_from_selected(&1, student_id))

  #   {:noreply, socket}
  # end

  # def handle_event("validate", %{"assessment_point" => params}, socket) do
  #   form =
  #     %AssessmentPoint{}
  #     |> Assessments.change_assessment_point(params)
  #     |> Map.put(:action, :validate)
  #     |> to_form()

  #   {:noreply, assign(socket, form: form)}
  # end

  # def handle_event("save", %{"assessment_point" => params}, socket) do
  #   classes_ids =
  #     socket.assigns.selected_classes
  #     |> Enum.map(fn {_name, id} -> id end)

  #   students_ids =
  #     socket.assigns.selected_students
  #     |> Enum.map(fn {_name, id} -> id end)

  #   params =
  #     params
  #     |> Map.put("classes_ids", classes_ids)
  #     |> Map.put("students_ids", students_ids)

  #   case Assessments.create_assessment_point(params) do
  #     {:ok, assessment_point} ->
  #       send(self(), {:assessment_point_created, assessment_point})
  #       {:noreply, socket}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, form: to_form(changeset))}
  #   end
  # end

  # defp extract_from_options(options, id) do
  #   Enum.find(
  #     options,
  #     fn {_key, value} -> value == id end
  #   )
  # end

  # defp merge_with_selected(selected, new) do
  #   new = if is_list(new), do: new, else: [new]
  #   selected ++ new
  # end

  # defp remove_from_selected(selected, id) do
  #   Enum.filter(
  #     selected,
  #     fn {_key, value} -> value != id end
  #   )
  # end
end
