defmodule LantternWeb.FiltersHelpers do
  @moduledoc """
  Helper functions related to `Filters` context
  """

  import Phoenix.Component, only: [assign: 3]

  alias Lanttern.Filters

  alias Lanttern.Identity.User
  alias Lanttern.Personalization
  alias Lanttern.Reporting
  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Schools
  alias Lanttern.Schools.Cycle
  alias Lanttern.StudentsRecords
  alias Lanttern.Taxonomy

  import LantternWeb.LocalizationHelpers

  @doc """
  Handle all filter related assigns in socket.

  ## Filter types and assigns

  ### `:subjects` assigns

  - `:subjects`
  - `:selected_subjects_ids`
  - `:selected_subjects`

  ### `:years` assigns

  - `:years`
  - `:selected_years_ids`
  - `:selected_years`

  ### `:assessment_view assigns

  - `:current_assessment_view`

  ### `:assessment_group_by` assigns

  - `:current_assessment_group_by`

  ### `:students` assigns

  - `:selected_students`
  - `:selected_students_ids`

  ### `:student_record_types` assigns

  - `:student_record_types` (filtered by user school)
  - `:selected_student_record_types`
  - `:selected_student_record_types_ids`

  ### `:student_record_statuses` assigns

  - `:student_record_statuses` (filtered by user school)
  - `:selected_student_record_statuses`
  - `:selected_student_record_statuses_ids`

  ### `:starred_strands`

  - `:only_starred_strands`

  ## Examples

      iex> assign_user_filters(socket, [:subjects], user)
      socket
  """
  @spec assign_user_filters(Phoenix.LiveView.Socket.t(), [atom()]) :: Phoenix.LiveView.Socket.t()
  def assign_user_filters(socket, filter_types) do
    current_user = socket.assigns.current_user

    current_filters = get_current_filters(current_user.current_profile_id)

    socket
    |> assign_filter_type(current_user, current_filters, filter_types)
  end

  defp get_current_filters(profile_id) do
    case Personalization.get_profile_settings(profile_id) do
      %{current_filters: current_filters} when not is_nil(current_filters) -> current_filters
      _ -> %{}
    end
  end

  defp assign_filter_type(socket, _current_user, _current_filters, []), do: socket

  defp assign_filter_type(socket, current_user, current_filters, [:subjects | filter_types]) do
    subjects =
      Taxonomy.list_subjects()
      |> translate_struct_list("taxonomy", :name, reorder: true)

    selected_subjects_ids = Map.get(current_filters, :subjects_ids) || []
    selected_subjects = Enum.filter(subjects, &(&1.id in selected_subjects_ids))

    socket
    |> assign(:subjects, subjects)
    |> assign(:selected_subjects_ids, selected_subjects_ids)
    |> assign(:selected_subjects, selected_subjects)
    |> assign_filter_type(current_user, current_filters, filter_types)
  end

  defp assign_filter_type(socket, current_user, current_filters, [:years | filter_types]) do
    years =
      Taxonomy.list_years()
      |> translate_struct_list("taxonomy")

    selected_years_ids = Map.get(current_filters, :years_ids) || []
    selected_years = Enum.filter(years, &(&1.id in selected_years_ids))

    socket
    |> assign(:years, years)
    |> assign(:selected_years_ids, selected_years_ids)
    |> assign(:selected_years, selected_years)
    |> assign_filter_type(current_user, current_filters, filter_types)
  end

  defp assign_filter_type(
         socket,
         current_user,
         current_filters,
         [:assessment_view | filter_types]
       ) do
    current_assessment_view =
      Map.get(current_filters, :assessment_view) || "teacher"

    socket
    |> assign(:current_assessment_view, current_assessment_view)
    |> assign_filter_type(current_user, current_filters, filter_types)
  end

  defp assign_filter_type(
         socket,
         current_user,
         current_filters,
         [:assessment_group_by | filter_types]
       ) do
    current_assessment_group_by =
      Map.get(current_filters, :assessment_group_by)

    socket
    |> assign(:current_assessment_group_by, current_assessment_group_by)
    |> assign_filter_type(current_user, current_filters, filter_types)
  end

  defp assign_filter_type(
         socket,
         current_user,
         current_filters,
         [:students | filter_types]
       ) do
    selected_students_ids = Map.get(current_filters, :students_ids) || []

    selected_students = Schools.list_students(students_ids: selected_students_ids)

    socket
    |> assign(:selected_students_ids, selected_students_ids)
    |> assign(:selected_students, selected_students)
    |> assign_filter_type(current_user, current_filters, filter_types)
  end

  defp assign_filter_type(
         socket,
         current_user,
         current_filters,
         [:student_record_types | filter_types]
       ) do
    school_id = current_user.current_profile.school_id

    student_record_types =
      StudentsRecords.list_student_record_types(school_id: school_id)

    selected_student_record_types_ids = Map.get(current_filters, :student_record_types_ids) || []

    selected_student_record_types =
      Enum.filter(student_record_types, &(&1.id in selected_student_record_types_ids))

    socket
    |> assign(:student_record_types, student_record_types)
    |> assign(:selected_student_record_types_ids, selected_student_record_types_ids)
    |> assign(:selected_student_record_types, selected_student_record_types)
    |> assign_filter_type(current_user, current_filters, filter_types)
  end

  defp assign_filter_type(
         socket,
         current_user,
         current_filters,
         [:student_record_statuses | filter_types]
       ) do
    school_id = current_user.current_profile.school_id

    student_record_statuses =
      StudentsRecords.list_student_record_statuses(school_id: school_id)

    selected_student_record_statuses_ids =
      Map.get(current_filters, :student_record_statuses_ids) || []

    selected_student_record_statuses =
      Enum.filter(student_record_statuses, &(&1.id in selected_student_record_statuses_ids))

    socket
    |> assign(:student_record_statuses, student_record_statuses)
    |> assign(:selected_student_record_statuses_ids, selected_student_record_statuses_ids)
    |> assign(:selected_student_record_statuses, selected_student_record_statuses)
    |> assign_filter_type(current_user, current_filters, filter_types)
  end

  defp assign_filter_type(
         socket,
         current_user,
         current_filters,
         [:starred_strands | filter_types]
       ) do
    socket
    |> assign(:only_starred_strands, Map.get(current_filters, :only_starred_strands))
    |> assign_filter_type(current_user, current_filters, filter_types)
  end

  defp assign_filter_type(socket, current_user, current_filters, [_ | filter_types]),
    do: assign_filter_type(socket, current_user, current_filters, filter_types)

  @type_to_filter_key_map %{
    subjects: :subjects_ids,
    years: :years_ids,
    cycles: :cycles_ids,
    classes: :classes_ids,
    linked_students_classes: :linked_students_classes_ids,
    students: :students_ids,
    student_record_types: :student_record_types_ids,
    student_record_statuses: :student_record_statuses_ids,
    starred_strands: :only_starred_strands
  }

  @type_to_current_value_key_map %{
    subjects: :selected_subjects_ids,
    years: :selected_years_ids,
    cycles: :selected_cycles_ids,
    classes: :selected_classes_ids,
    linked_students_classes: :selected_linked_students_classes_ids,
    students: :selected_students_ids,
    student_record_types: :selected_student_record_types_ids,
    student_record_statuses: :selected_student_record_statuses_ids,
    starred_strands: :only_starred_strands
  }

  @doc """
  Handle classes filter assigns in socket.

  ## Opts

  Any opts accepted in `list_user_classes/2`.

  ## Expected assigns in socket

  - `current_user` - used to get the current cycle information

  ## Returned socket assigns

  - `:classes`
  - `:selected_classes_ids`
  - `:selected_classes`

  ## Examples

      iex> assign_classes_filter(socket)
      socket
  """
  @spec assign_classes_filter(Phoenix.LiveView.Socket.t(), opts :: Keyword.t()) ::
          Phoenix.LiveView.Socket.t()
  def assign_classes_filter(socket, opts \\ []) do
    classes =
      Schools.list_user_classes(socket.assigns.current_user, opts)

    selected_classes_ids =
      case Personalization.get_profile_settings(socket.assigns.current_user.current_profile_id) do
        %{current_filters: current_filters} when not is_nil(current_filters) -> current_filters
        _ -> %{}
      end
      |> Map.get(:classes_ids) || []

    selected_classes = Enum.filter(classes, &(&1.id in selected_classes_ids))

    # as classes may be filtered (by cycle, for example), selected classes
    # may have more classes than the listed. we check for this case below,
    # and adjust classes and selected classes as needed

    classes_ids = Enum.map(classes, & &1.id)

    selected_classes_ids_not_in_classes =
      Enum.filter(selected_classes_ids, &(&1 not in classes_ids))

    selected_classes_not_in_classes =
      if selected_classes_ids_not_in_classes != [] do
        Schools.list_classes(classes_ids: selected_classes_ids_not_in_classes)
      else
        []
      end

    classes = classes ++ selected_classes_not_in_classes
    selected_classes = selected_classes ++ selected_classes_not_in_classes

    socket
    |> assign(:classes, classes)
    |> assign(:selected_classes_ids, selected_classes_ids)
    |> assign(:selected_classes, selected_classes)
  end

  @doc """
  Handle strand classes filter assigns in socket.

  ## Expected assigns in socket

  - `current_user` - used to get the current cycle information
  - `strand` with preloaded `years` - used to filter classes by

  ## Returned socket assigns

  - `:classes`
  - `:selected_classes_ids`
  - `:selected_classes`

  ## Examples

      iex> assign_strand_classes_filter(socket)
      socket
  """
  @spec assign_strand_classes_filter(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def assign_strand_classes_filter(socket) do
    %{
      current_user: %{
        current_profile: %{
          id: profile_id,
          school_id: school_id,
          current_school_cycle: school_cycle
        }
      },
      strand: %{id: strand_id, years: years}
    } = socket.assigns

    selected_classes_ids =
      Filters.list_profile_strand_filters_classes_ids(profile_id, strand_id)

    years_ids = Enum.map(years, & &1.id)

    cycles_ids =
      case school_cycle do
        %Cycle{} -> [school_cycle.id]
        _ -> nil
      end

    classes =
      Schools.list_classes(
        schools_ids: [school_id],
        years_ids: years_ids,
        cycles_ids: cycles_ids
      )

    selected_classes = Enum.filter(classes, &(&1.id in selected_classes_ids))

    # as classes are filtered by years and cycles, selected classes
    # may have more classes than the listed. we check for this case below,
    # and adjust classes and selected classes as needed

    classes_ids = Enum.map(classes, & &1.id)

    selected_classes_ids_not_in_classes =
      Enum.filter(selected_classes_ids, &(&1 not in classes_ids))

    selected_classes_not_in_classes =
      if selected_classes_ids_not_in_classes != [] do
        Schools.list_classes(classes_ids: selected_classes_ids_not_in_classes)
      else
        []
      end

    classes = classes ++ selected_classes_not_in_classes
    selected_classes = selected_classes ++ selected_classes_not_in_classes

    socket
    |> assign(:classes, classes)
    |> assign(:selected_classes_ids, selected_classes_ids)
    |> assign(:selected_classes, selected_classes)
  end

  @doc """
  Handle cycle filter assigns in socket.

  ## Options

  ### `only_subcycles` (`boolean`)

  When `only_subcycles: true`, will list only subcycles of the user's
  current school cycle. If user has a selected cycle that are not part
  of the listed subcycles, it's not considered as selected.

  In case `only_subcycles: true` but the current user doesn't have a
  current school cycle selected, the function will work as if the opt is `false`.

  ## Filter assigns

  - `:cycles`
  - `:selected_cycles_ids`
  - `:selected_cycles`

  ## Examples

      iex> assign_cycle_filter(socket)
      socket
  """
  @spec assign_cycle_filter(Phoenix.LiveView.Socket.t(), opts :: Keyword.t()) ::
          Phoenix.LiveView.Socket.t()
  def assign_cycle_filter(socket, opts \\ []) do
    current_user = socket.assigns.current_user
    current_filters = get_current_filters(current_user.current_profile_id)

    socket
    |> set_assign_cycle_filter_socket(current_user, current_filters, opts)
  end

  defp set_assign_cycle_filter_socket(
         socket,
         %{current_profile: %{current_school_cycle: %Cycle{}}} = current_user,
         current_filters,
         only_subcycles: true
       ) do
    subcycles =
      Schools.list_cycles(
        schools_ids: [current_user.current_profile.school_id],
        subcycles_of_parent_id: Map.get(current_user.current_profile.current_school_cycle, :id)
      )

    subcycles_ids = Enum.map(subcycles, & &1.id)

    # if there are selected cycles outside of the scope of subcycles,
    # consider that they are not selected
    selected_subcycles_ids =
      (Map.get(current_filters, :cycles_ids) || [])
      |> Enum.filter(&(&1 in subcycles_ids))

    selected_subcycles = Enum.filter(subcycles, &(&1.id in selected_subcycles_ids))

    socket
    |> assign(:cycles, subcycles)
    |> assign(:selected_cycles_ids, selected_subcycles_ids)
    |> assign(:selected_cycles, selected_subcycles)
  end

  defp set_assign_cycle_filter_socket(socket, current_user, current_filters, _only_subcycles) do
    cycles = Schools.list_cycles(schools_ids: [current_user.current_profile.school_id])

    selected_cycles_ids = Map.get(current_filters, :cycles_ids) || []
    selected_cycles = Enum.filter(cycles, &(&1.id in selected_cycles_ids))

    socket
    |> assign(:cycles, cycles)
    |> assign(:selected_cycles_ids, selected_cycles_ids)
    |> assign(:selected_cycles, selected_cycles)
  end

  @doc """
  Handle report card linked student classes filter assigns in socket.



  ## Filter assigns

  - `:linked_students_classes`
  - `:selected_linked_students_classes_ids`
  - `:selected_linked_students_classes`

  ## Examples

      iex> assign_report_card_linked_student_classes_filter(socket)
      socket
  """
  @spec assign_report_card_linked_student_classes_filter(
          Phoenix.LiveView.Socket.t(),
          report_card :: ReportCard.t()
        ) ::
          Phoenix.LiveView.Socket.t()
  def assign_report_card_linked_student_classes_filter(socket, %ReportCard{} = report_card) do
    current_user = socket.assigns.current_user

    current_filters =
      Filters.list_profile_report_card_filters(current_user.current_profile_id, report_card.id)

    socket
    |> set_assign_report_card_linked_student_classes_filter_socket(current_filters, report_card)
  end

  defp set_assign_report_card_linked_student_classes_filter_socket(
         socket,
         current_filters,
         report_card
       ) do
    classes =
      Reporting.list_report_card_linked_students_classes(report_card)

    selected_classes_ids = Map.get(current_filters, :linked_students_classes_ids) || []
    selected_classes = Enum.filter(classes, &(&1.id in selected_classes_ids))

    socket
    |> assign(:linked_students_classes, classes)
    |> assign(:selected_linked_students_classes_ids, selected_classes_ids)
    |> assign(:selected_linked_students_classes, selected_classes)
  end

  @doc """
  Handle toggling of filter related assigns in socket.

  ## Supported types

  - `:subjects`
  - `:years`
  - `:cycles`
  - `:classes`

  ## Examples

      iex> handle_filter_toggle(socket, :subjects, 1)
      %Phoenix.LiveView.Socket{}
  """

  @spec handle_filter_toggle(Phoenix.LiveView.Socket.t(), atom(), pos_integer()) ::
          Phoenix.LiveView.Socket.t()

  def handle_filter_toggle(socket, type, id) do
    selected_ids_key = @type_to_current_value_key_map[type]
    selected_ids = socket.assigns[selected_ids_key]

    selected_ids =
      case id in selected_ids do
        true ->
          selected_ids
          |> Enum.filter(&(&1 != id))

        false ->
          [id | selected_ids]
      end

    assign(socket, selected_ids_key, selected_ids)
  end

  @doc """
  Handle clearing of profile filters.

  ## Supported opts

  - `:strand_id` - will persist data in the strand context. supports `:classes` type
  - `:report_card_id` - will persist data in the report card context. supports `:classes` type

  ## Supported types

  - `:subjects`
  - `:years`
  - `:cycles`
  - `:classes`

  ## Examples

      iex> clear_profile_filters(user, [:subjects])
      {:ok, %ProfileSettings{}}

      iex> clear_profile_filters(user, bad_value)
      {:error, %Ecto.Changeset{}}
  """

  @spec clear_profile_filters(User.t(), [atom()], Keyword.t()) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}

  def clear_profile_filters(current_user, types, opts \\ []) do
    attrs =
      types
      |> Enum.map(&{@type_to_filter_key_map[&1], []})
      |> Enum.into(%{})

    apply_save_profile_filters(current_user, attrs, opts)
  end

  @doc """
  Handle saving of profile filters.

  ## Supported opts

  - `:strand_id` - will persist data in the strand context. supports `:classes` type
  - `:report_card_id` - will persist data in the report card context. supports `:classes` type

  ## Supported types

  - `:subjects`
  - `:years`
  - `:cycles`
  - `:students`
  - `:student_record_types`
  - `:student_record_status`

  ## Examples

      iex> save_profile_filters(socket, user, [:subjects])
      %Phoenix.LiveView.Socket{}
  """

  @spec save_profile_filters(Phoenix.LiveView.Socket.t(), [atom()], Keyword.t()) ::
          Phoenix.LiveView.Socket.t()

  def save_profile_filters(socket, types, opts \\ []) do
    current_user = socket.assigns.current_user

    attrs =
      types
      |> Enum.map(fn type ->
        filter_key = @type_to_current_value_key_map[type]
        current_filter_value = socket.assigns[filter_key]

        {@type_to_filter_key_map[type], current_filter_value}
      end)
      |> Enum.into(%{})

    apply_save_profile_filters(current_user, attrs, opts)

    socket
  end

  defp apply_save_profile_filters(current_user, attrs, strand_id: strand_id)
       when is_integer(strand_id),
       do: Filters.set_profile_strand_filters(current_user, strand_id, attrs)

  defp apply_save_profile_filters(current_user, attrs, report_card_id: report_card_id)
       when is_integer(report_card_id),
       do: Filters.set_profile_report_card_filters(current_user, report_card_id, attrs)

  defp apply_save_profile_filters(current_user, attrs, _),
    do: Filters.set_profile_current_filters(current_user, attrs)
end
