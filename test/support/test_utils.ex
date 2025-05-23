defmodule Lanttern.Support.TestUtils do
  @moduledoc """
  Test utilities for Lanttern
  """

  alias Phoenix.LiveViewTest

  @doc "Open stardard browser in Windows for WSL users"
  def open_browser_wsl(view) do
    LiveViewTest.open_browser(view, fn html_unix_path ->
      {wsl_path, 0} = System.cmd("wslpath", ["-aw", html_unix_path])
      cmd_args = ["/C", "start", String.trim_trailing(wsl_path), "/C", "bash"]

      System.cmd("cmd.exe", cmd_args)
    end)
  end
end
