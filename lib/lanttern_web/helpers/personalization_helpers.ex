defmodule LantternWeb.PersonalizationHelpers do
  import Phoenix.Component, only: [assign: 3]

  alias Lanttern.Personalization

  alias Lanttern.Identity.User
  alias Lanttern.Taxonomy

  import LantternWeb.LocalizationHelpers

  @doc """
  Handle filter related assigns in socket.

  ## Filter types and assigns

  ### `:subjects`'s assigns

  - :subjects
  - :selected_subjects_ids
  - :selected_subjects

  ### `:years`'s assigns

  - :years
  - :selected_years_ids
  - :selected_years

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
    |> assign_filter_type(current_filters, filter_types)
  end

  defp assign_filter_type(socket, _current_filters, []), do: socket

  defp assign_filter_type(socket, current_filters, [:subjects | filter_types]) do
    subjects =
      Taxonomy.list_subjects()
      |> translate_struct_list("taxonomy", :name, reorder: true)

    selected_subjects_ids = Map.get(current_filters, :subjects_ids) || []
    selected_subjects = Enum.filter(subjects, &(&1.id in selected_subjects_ids))

    socket
    |> assign(:subjects, subjects)
    |> assign(:selected_subjects_ids, selected_subjects_ids)
    |> assign(:selected_subjects, selected_subjects)
    |> assign_filter_type(current_filters, filter_types)
  end

  defp assign_filter_type(socket, current_filters, [:years | filter_types]) do
    years =
      Taxonomy.list_years()
      |> translate_struct_list("taxonomy")

    selected_years_ids = Map.get(current_filters, :years_ids) || []
    selected_years = Enum.filter(years, &(&1.id in selected_years_ids))

    socket
    |> assign(:years, years)
    |> assign(:selected_years_ids, selected_years_ids)
    |> assign(:selected_years, selected_years)
    |> assign_filter_type(current_filters, filter_types)
  end

  defp assign_filter_type(socket, current_filters, [_ | filter_types]),
    do: assign_filter_type(socket, current_filters, filter_types)
end
