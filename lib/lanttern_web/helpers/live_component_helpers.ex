defmodule LantternWeb.LiveComponentHelpers do
  @moduledoc """
  Set of reusable helpers for live components
  """

  @doc """
  Send notification to parent based on `:notify_parent` assign.
  """
  def notify_parent(module, msg, %{notify_parent: true}),
    do: send(self(), {module, msg})

  def notify_parent(_module, _msg, _assigns), do: nil

  @doc """
  Send update to component based on `:notify_component` assign.
  """
  def notify_component(module, msg, %{notify_component: %Phoenix.LiveComponent.CID{} = cid}),
    do: Phoenix.LiveView.send_update(cid, action: {module, msg})

  def notify_component(_module, _msg, _assigns), do: nil

  @doc """
  Handles navigation based on socket assigns.

  Usually used to navigate after successful actions.
  """
  def handle_navigation(socket, arg \\ %{})

  def handle_navigation(%{assigns: %{patch: patch}} = socket, arg) when is_function(patch),
    do: Phoenix.LiveView.push_patch(socket, to: patch.(arg))

  def handle_navigation(%{assigns: %{patch: patch}} = socket, _arg),
    do: Phoenix.LiveView.push_patch(socket, to: patch)

  def handle_navigation(%{assigns: %{navigate: navigate}} = socket, arg)
      when is_function(navigate),
      do: Phoenix.LiveView.push_navigate(socket, to: navigate.(arg))

  def handle_navigation(%{assigns: %{navigate: navigate}} = socket, _arg),
    do: Phoenix.LiveView.push_navigate(socket, to: navigate)

  def handle_navigation(socket, _arg), do: socket

  @doc """
  Friendly error messages for `Phoenix.Component.upload_errors/2`.
  """
  def error_to_string(upload_config = %Phoenix.LiveView.UploadConfig{}, :not_accepted) do
    formats =
      upload_config.accept
      |> String.split(",")
      |> format_formats_list()

    "Only #{formats} files accepted"
  end

  def error_to_string(upload_config = %Phoenix.LiveView.UploadConfig{}, :too_large),
    do: "File too large (max. #{upload_config.max_file_size / 1_000_000}MB)"

  def error_to_string(_upload_config, err), do: err

  defp format_formats_list([format]), do: format

  defp format_formats_list([format_1, format_2]), do: "#{format_1} and #{format_2}"

  defp format_formats_list(formats) do
    {rest, last} = Enum.split(formats, -1)

    (rest ++ ["and #{last}"])
    |> Enum.join(", ")
  end
end
