defmodule LantternWeb.PrivacyPolicyHTML do
  use LantternWeb, :html

  embed_templates "privacy_policy_html/*"

  def link(text, to) do
    "#{text}, to: #{to}"
  end
end
