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
    [
      "default-src 'self' *.google.com *.googleapis.com",
      "script-src 'self' 'nonce-#{nonce}' *.googletagmanager.com *.googleapis.com",
      "style-src 'self' 'unsafe-inline' *.googleapis.com *.google.com",
      "img-src * data: blob: 'self'",
      "font-src *",
      "media-src 'self' *.supabase.co",
      "connect-src 'self' *.supabase.co *.google-analytics.com *.google.com *.googletagmanager.com"
    ]
    |> Enum.join("; ")
  end
end
