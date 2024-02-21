defmodule LantternWeb.PageHTML do
  use LantternWeb, :html

  import LantternWeb.GradingComponents

  embed_templates "page_html/*"
end
