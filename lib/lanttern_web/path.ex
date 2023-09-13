defmodule LantternWeb.Path do
  @doc """
  Sets the path from the connection as :current_path on the socket
  """
  def on_mount(:put_path_in_socket, _params, _session, socket),
    do:
      {:cont,
       Phoenix.LiveView.attach_hook(
         socket,
         :put_path_in_socket,
         :handle_params,
         &put_path_in_socket/3
       )}

  defp put_path_in_socket(_params, url, socket),
    do: {:cont, Phoenix.Component.assign(socket, :current_path, URI.parse(url).path)}
end
