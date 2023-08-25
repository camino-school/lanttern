defmodule LantternWeb.AdminController do
  use LantternWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
