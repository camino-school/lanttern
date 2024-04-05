defmodule LantternWeb.AssessmentsHelpers do
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
  TBD
  """
  @type changes_map() :: %{
          optional(binary) => {type :: atom(), entry_id :: pos_integer(), params :: map()}
        }

  @spec save_entry_editor_component_changes(changes_map()) ::
          {:ok | :error, results_message :: binary()}
  def save_entry_editor_component_changes(changes_map) do
    changes =
      changes_map
      |> Enum.map(fn {_, change} -> change end)

    case apply_save_changes(changes) do
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
         results \\ %{created: 0, updated: 0, deleted: 0}
       )

  defp apply_save_changes([], results), do: {:ok, results}

  defp apply_save_changes([{:new, _entry_id, params} | changes], results) do
    case Assessments.create_assessment_point_entry(params) do
      {:ok, _assessment_point_entry} ->
        apply_save_changes(
          changes,
          Map.update!(results, :created, &(&1 + 1))
        )

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, gettext("Error creating assessment point entry"), results}
    end
  end

  defp apply_save_changes(
         [{:delete, entry_id, _params} | changes],
         results
       ) do
    with entry when not is_nil(entry) <- Assessments.get_assessment_point_entry(entry_id) do
      case Assessments.delete_assessment_point_entry(entry) do
        {:ok, _assessment_point_entry} ->
          apply_save_changes(
            changes,
            Map.update!(results, :deleted, &(&1 + 1))
          )

        {:error, %Ecto.Changeset{} = _changeset} ->
          {:error, gettext("Error deleting assessment point entry"), results}
      end
    else
      _ -> {:error, gettext("The entry does not exist anymore"), results}
    end
  end

  defp apply_save_changes([{:edit, entry_id, params} | changes], results) do
    with entry when not is_nil(entry) <- Assessments.get_assessment_point_entry(entry_id) do
      case Assessments.update_assessment_point_entry(entry, params) do
        {:ok, _assessment_point_entry} ->
          apply_save_changes(
            changes,
            Map.update!(results, :updated, &(&1 + 1))
          )

        {:error, %Ecto.Changeset{} = _changeset} ->
          {:error, gettext("Error updating assessment point entry"), results}
      end
    else
      _ -> {:error, gettext("The entry does not exist anymore"), results}
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
