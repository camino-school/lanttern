defmodule LantternWeb.PersonalizationHelpers do
  import Phoenix.Component, only: [assign: 3]

  alias Lanttern.Personalization
  alias Lanttern.Personalization.ProfileSettings

  alias Lanttern.Identity.User
  alias Lanttern.Schools
  alias Lanttern.Taxonomy

  import LantternWeb.LocalizationHelpers

  @doc """
  Handle all filter related assigns in socket.

  ## Filter types and assigns

  ### `:subjects`' assigns

  - :subjects
  - :selected_subjects_ids
  - :selected_subjects

  ### `:years`' assigns

  - :years
  - :selected_years_ids
  - :selected_years

  ### `:cycles`' assigns

  - :cycles
  - :selected_cycles_ids
  - :selected_cycles

  ### `:classes`' assigns

  - :classes
  - :selected_classes_ids
  - :selected_classes

  ## Examples

      iex> assign_user_filters(socket, [:subjects], user)
      socket
  """
  @spec assign_user_filters(Phoenix.LiveView.Socket.t(), [atom()], User.t()) ::
          Phoenix.LiveView.Socket.t()
  def assign_user_filters(socket, filter_types, %User{} = current_user) do
    current_filters =
      case Personalization.get_profile_settings(current_user.current_profile_id) do
        %{current_filters: current_filters} -> current_filters
        _ -> %{}
      end

    socket
    |> assign_filter_type(current_user, current_filters, filter_types)
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

  defp assign_filter_type(socket, current_user, current_filters, [:cycles | filter_types]) do
    cycles =
      Schools.list_cycles(schools_ids: [current_user.current_profile.school_id])

    selected_cycles_ids = Map.get(current_filters, :cycles_ids) || []
    selected_cycles = Enum.filter(cycles, &(&1.id in selected_cycles_ids))

    socket
    |> assign(:cycles, cycles)
    |> assign(:selected_cycles_ids, selected_cycles_ids)
    |> assign(:selected_cycles, selected_cycles)
    |> assign_filter_type(current_user, current_filters, filter_types)
  end

  defp assign_filter_type(socket, current_user, current_filters, [:classes | filter_types]) do
    classes =
      Schools.list_user_classes(current_user)

    selected_classes_ids = Map.get(current_filters, :classes_ids) || []
    selected_classes = Enum.filter(classes, &(&1.id in selected_classes_ids))

    socket
    |> assign(:classes, classes)
    |> assign(:selected_classes_ids, selected_classes_ids)
    |> assign(:selected_classes, selected_classes)
    |> assign_filter_type(current_user, current_filters, filter_types)
  end

  defp assign_filter_type(socket, current_user, current_filters, [_ | filter_types]),
    do: assign_filter_type(socket, current_user, current_filters, filter_types)

  @type_to_type_ids_key_map %{
    subjects: :subjects_ids,
    years: :years_ids,
    cycles: :cycles_ids,
    classes: :classes_ids
  }

  @type_to_selected_ids_key_map %{
    subjects: :selected_subjects_ids,
    years: :selected_years_ids,
    cycles: :selected_cycles_ids,
    classes: :selected_classes_ids
  }

  @doc """
  Handle toggling of filter related assigns in socket.

  ## Supported types

  - `:subjects`
  - `:years`
  - `:cycles`

  ## Examples

      iex> handle_filter_toggle(socket, :subjects, 1)
      %Phoenix.LiveView.Socket{}
  """

  @spec handle_filter_toggle(Phoenix.LiveView.Socket.t(), atom(), pos_integer()) ::
          Phoenix.LiveView.Socket.t()

  def handle_filter_toggle(socket, type, id) do
    selected_ids_key = @type_to_selected_ids_key_map[type]
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

  ## Supported types

  - `:subjects`
  - `:years`
  - `:cycles`

  ## Examples

      iex> clear_profile_filters(user, [:subjects])
      {:ok, %ProfileSettings{}}

      iex> clear_profile_filters(user, bad_value)
      {:error, %Ecto.Changeset{}}
  """

  @spec clear_profile_filters(User.t(), [atom()]) ::
          {:ok, ProfileSettings.t()} | {:error, Ecto.Changeset.t()}

  def clear_profile_filters(current_user, types) do
    attrs =
      types
      |> Enum.map(&{@type_to_type_ids_key_map[&1], []})
      |> Enum.into(%{})

    Personalization.set_profile_current_filters(current_user, attrs)
  end

  @doc """
  Handle saving of profile filters.

  ## Supported types

  - `:subjects`
  - `:years`
  - `:cycles`

  ## Examples

      iex> save_profile_filters(socket, user, [:subjects])
      %Phoenix.LiveView.Socket{}
  """

  @spec save_profile_filters(Phoenix.LiveView.Socket.t(), User.t(), [atom()]) ::
          Phoenix.LiveView.Socket.t()

  def save_profile_filters(socket, current_user, types) do
    attrs =
      types
      |> Enum.map(fn type ->
        selected_ids_key = @type_to_selected_ids_key_map[type]
        selected_ids = socket.assigns[selected_ids_key]

        {@type_to_type_ids_key_map[type], selected_ids}
      end)
      |> Enum.into(%{})

    Personalization.set_profile_current_filters(current_user, attrs)

    socket
  end
end
