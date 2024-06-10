defmodule LantternWeb.AssessmentsHelpers do
  @moduledoc """
  Shared function components related to `Assessments` context
  """

  import LantternWeb.Gettext

  alias Lanttern.Assessments

  @doc """
  Generate list of assessment poiints to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_assessment_point_options()
      ["assessment point name": 1, ...]
  """
  def generate_assessment_point_options() do
    Assessments.list_assessment_points()
    |> Enum.map(fn ap -> {ap.name, ap.id} end)
  end

  @doc """
  Iterate over an entry editor component changes map and save all changes.

  Logs all entries.
  """
  @type changes_map() :: %{
          optional(String.t()) => {type :: atom(), entry_id :: pos_integer(), params :: map()}
        }

  @spec save_entry_editor_component_changes(changes_map(), profile_id :: pos_integer() | nil) ::
          {:ok | :error, results_message :: String.t()}
  def save_entry_editor_component_changes(changes_map, profile_id \\ nil) do
    changes =
      changes_map
      |> Enum.map(fn {_, change} -> change end)

    case apply_save_changes(changes, profile_id) do
      {:ok, results} ->
        msg = build_save_changes_results_message(results)
        {:ok, msg}

      {:error, msg, results} ->
        results_so_far_msg = build_save_changes_results_message(results)

        msg =
          case results_so_far_msg == "" do
            true ->
              msg

            false ->
              "#{msg} (#{gettext("Results so far")}: #{results_so_far_msg})"
          end

        {:error, msg}
    end
  end

  defp apply_save_changes(
         changes,
         profile_id,
         results \\ %{created: 0, updated: 0, deleted: 0}
       )

  defp apply_save_changes([], _, results), do: {:ok, results}

  defp apply_save_changes([{:new, _entry_id, params} | changes], profile_id, results) do
    case Assessments.create_assessment_point_entry(params, log_profile_id: profile_id) do
      {:ok, _assessment_point_entry} ->
        apply_save_changes(
          changes,
          profile_id,
          Map.update!(results, :created, &(&1 + 1))
        )

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, gettext("Error creating assessment point entry"), results}
    end
  end

  defp apply_save_changes(
         [{:delete, entry_id, _params} | changes],
         profile_id,
         results
       ) do
    case Assessments.get_assessment_point_entry(entry_id) do
      entry when not is_nil(entry) ->
        case Assessments.delete_assessment_point_entry(entry, log_profile_id: profile_id) do
          {:ok, _assessment_point_entry} ->
            apply_save_changes(
              changes,
              profile_id,
              Map.update!(results, :deleted, &(&1 + 1))
            )

          {:error, %Ecto.Changeset{} = _changeset} ->
            {:error, gettext("Error deleting assessment point entry"), results}
        end

      _ ->
        {:error, gettext("The entry does not exist anymore"), results}
    end
  end

  defp apply_save_changes([{:edit, entry_id, params} | changes], profile_id, results) do
    case Assessments.get_assessment_point_entry(entry_id) do
      entry when not is_nil(entry) ->
        case Assessments.update_assessment_point_entry(entry, params, log_profile_id: profile_id) do
          {:ok, _assessment_point_entry} ->
            apply_save_changes(
              changes,
              profile_id,
              Map.update!(results, :updated, &(&1 + 1))
            )

          {:error, %Ecto.Changeset{} = _changeset} ->
            {:error, gettext("Error updating assessment point entry"), results}
        end

      _ ->
        {:error, gettext("The entry does not exist anymore"), results}
    end
  end

  defp build_save_changes_results_message(%{} = results),
    do: build_save_changes_results_message(Enum.map(results, & &1), [])

  defp build_save_changes_results_message([], msgs),
    do: Enum.join(msgs, ", ")

  defp build_save_changes_results_message([{_operation, 0} | results], msgs),
    do: build_save_changes_results_message(results, msgs)

  defp build_save_changes_results_message([{:created, count} | results], msgs) do
    msg = ngettext("1 entry created", "%{count} entries created", count)
    build_save_changes_results_message(results, [msg | msgs])
  end

  defp build_save_changes_results_message([{:updated, count} | results], msgs) do
    msg = ngettext("1 entry updated", "%{count} entries updated", count)
    build_save_changes_results_message(results, [msg | msgs])
  end

  defp build_save_changes_results_message([{:deleted, count} | results], msgs) do
    msg = ngettext("1 entry removed", "%{count} entries removed", count)
    build_save_changes_results_message(results, [msg | msgs])
  end
end
