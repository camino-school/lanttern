defmodule LantternWeb.PutSecureBrowserHeadersPlug do
  @moduledoc """
  Sets the Content-Security-Policy header with a per-request nonce.
  Assigns `csp_nonce` to the conn for use in templates.
  """

  @behaviour Plug

  @impl true
  def init(_opts), do: []

  @impl true
  def call(conn, _opts) do
    nonce = :crypto.strong_rand_bytes(16) |> Base.encode64(padding: false)

    conn
    |> Plug.Conn.assign(:csp_nonce, nonce)
    |> Phoenix.Controller.put_secure_browser_headers(%{
      "content-security-policy" => build_csp(nonce)
    })
  end

  defp build_csp(nonce) do
    vite_host = Application.get_env(:live_react, :vite_host)

    [
      "default-src 'self' *.google.com *.googleapis.com",
      script_src(nonce, vite_host),
      style_src(vite_host),
      "img-src * data: blob: 'self'",
      "font-src *",
      "media-src 'self' *.supabase.co",
      connect_src(vite_host)
    ]
    |> Enum.join("; ")
  end

  defp script_src(nonce, nil),
    do: "script-src 'self' 'nonce-#{nonce}' *.google.com *.googletagmanager.com *.googleapis.com"

  # In dev, we use 'unsafe-inline' instead of a nonce. A nonce-based policy causes browsers
  # to ignore 'unsafe-inline', which would block the unnonce'd React Refresh preamble injected
  # by LiveReact.Reload.vite_assets.
  defp script_src(_nonce, vite_host),
    do:
      "script-src 'self' 'unsafe-inline' #{vite_host} *.google.com *.googletagmanager.com *.googleapis.com"

  defp style_src(nil),
    do: "style-src 'self' 'unsafe-inline' *.googleapis.com *.google.com"

  defp style_src(vite_host),
    do: "style-src 'self' 'unsafe-inline' #{vite_host} *.googleapis.com *.google.com"

  defp connect_src(nil),
    do:
      "connect-src 'self' *.supabase.co *.google-analytics.com *.google.com *.googletagmanager.com"

  defp connect_src(vite_host) do
    # ws:// equivalent of the vite_host for HMR websocket
    ws_host = String.replace(vite_host, ~r/^https?/, "ws")

    "connect-src 'self' #{vite_host} #{ws_host} *.supabase.co *.google-analytics.com *.google.com *.googletagmanager.com"
  end
end
