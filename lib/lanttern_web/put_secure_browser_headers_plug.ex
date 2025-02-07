# based on "Wrapping existing Plugs with your own Plugs" opt
# in https://akoutmos.com/post/plug-runtime-config/

defmodule LantternWeb.PutSecureBrowserHeadersPlug do
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
