defmodule LantternWeb.RubricsLive.Explorer do
  use LantternWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <.page_title_with_menu>Rubrics explorer</.page_title_with_menu>
      <%!-- <div class="mt-12">
        <p class="font-display font-bold text-lg">
          I want to explore assessment points<br /> in
          <.filter_buttons type="subjects" items={@current_subjects} />, from
          <.filter_buttons type="classes" items={@current_classes} />
        </p>
      </div> --%>
    </div>
    """
  end

  # lifecycle

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
