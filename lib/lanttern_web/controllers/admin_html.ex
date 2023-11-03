defmodule LantternWeb.AdminHTML do
  use LantternWeb, :html

  embed_templates "admin_html/*"

  attr :title, :string, required: true

  slot :item do
    attr :link, :string, required: true
  end

  def link_list(assigns) do
    ~H"""
    <div>
      <h2 class="font-display font-black text-xl"><%= @title %></h2>
      <ul>
        <li :for={item <- @item}>
          <.link href={item.link}>
            <%= render_slot(item) %>
          </.link>
        </li>
      </ul>
    </div>
    """
  end
end
