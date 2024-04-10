defmodule LantternWeb.PrivacyPolicyController do
  use LantternWeb, :controller
  import LantternWeb.Gettext

  alias Lanttern.Identity

  def policy(conn, _params) do
    page_title = gettext("Privacy policy")
    render(conn, :policy, page_title: page_title)
  end

  def accept_policy(conn, _params) do
    page_title = gettext("Privacy policy")

    privacy_policy_link_str =
      "<a href='/privacy_policy' target='_blank' class='underline hover:text-ltrn-subtle'>#{gettext("privacy policy")}</a>"

    render(conn, :accept_policy,
      page_title: page_title,
      privacy_policy_link_str: privacy_policy_link_str,
      error: nil
    )
  end

  def save_accept_policy(conn, _params) do
    remote_ip =
      conn.remote_ip
      |> Tuple.to_list()
      |> Enum.join(".")

    {_, user_agent} =
      conn.req_headers
      |> Enum.find(fn {header, _value} -> header == "user-agent" end)

    user = conn.assigns.current_user
    meta = "IP: #{remote_ip}, User agent: #{user_agent}"

    case Identity.update_user_privacy_policy_accepted(user, meta) do
      {:ok, _user} ->
        user_return_to = get_session(conn, :user_return_to)

        conn
        |> redirect(to: user_return_to || ~p"/dashboard")

      {:error, _changeset} ->
        page_title = gettext("Privacy policy")

        privacy_policy_link_str =
          "<a href='/privacy_policy' target='_blank' class='underline hover:text-ltrn-subtle'>#{gettext("privacy policy")}</a>"

        error = gettext("Something went wrong")

        render(conn, :accept_policy,
          page_title: page_title,
          privacy_policy_link_str: privacy_policy_link_str,
          error: error
        )
    end
  end
end
