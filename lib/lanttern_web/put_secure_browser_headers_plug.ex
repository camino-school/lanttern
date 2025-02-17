# based on "Wrapping existing Plugs with your own Plugs" opt
# in https://akoutmos.com/post/plug-runtime-config/

defmodule LantternWeb.PutSecureBrowserHeadersPlug do
  @moduledoc """
  `Phoenix.Controller.put_secure_browser_headers/2` wrapper.
  Enables the use of `Application.get_env/2` to set the CSP header.
  """

  @behaviour Plug

  @default_csp "default-src 'self'"

  @impl true
  def init(_opts) do
    []
  end

  @impl true
  def call(conn, _opts) do
    headers =
      %{
        "content-security-policy" =>
          Application.get_env(:lanttern, :content_security_policy) || @default_csp
      }

    Phoenix.Controller.put_secure_browser_headers(conn, headers)
  end
end
