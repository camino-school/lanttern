defmodule LantternWeb.RubricsLive.Explorer do
  use LantternWeb, :live_view

  alias Lanttern.Rubrics

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
      <div class="flex items-center gap-4 justify-between mt-10">
        <div class="flex items-center gap-4 text-sm">
          <p class="flex items-center gap-2">
            Showing <%= @results %> results
          </p>
        </div>
        <button class="shrink-0 flex items-center gap-2 text-sm text-ltrn-subtle hover:underline">
          Create rubric <.icon name="hero-plus-mini" class="text-ltrn-primary" />
        </button>
      </div>
      <div id="rubrics-list" phx-update="stream">
        <div
          :for={{dom_id, rubric} <- @streams.rubrics}
          class="w-full p-6 mt-4 rounded shadow-xl bg-white"
          id={dom_id}
        >
          <div class="flex items-start justify-between mb-4">
            <div class="flex-1">
              <p class="font-display font-black text-lg">Criteria: <%= rubric.criteria %></p>
              <div class="flex items-center gap-4 mt-4 text-base">
                <.icon name="hero-view-columns" class="shrink-0 text-rose-500" /> <%= rubric.scale.name %>
              </div>
            </div>
            <div class="shrink-0 flex items-center gap-2">
              <.button type="button" theme="ghost">Id #<%= rubric.id %></.button>
              <.button type="button" theme="ghost">Edit</.button>
              <.badge :if={rubric.is_differentiation} theme="secondary">Differentiation</.badge>
            </div>
          </div>
          <div class="flex items-stretch gap-2">
            <div
              :for={descriptor <- rubric.descriptors}
              class="flex-[1_0] flex flex-col items-start gap-2"
            >
              <%= if descriptor.scale_type == "numeric" do %>
                <.badge theme="dark"><%= descriptor.score %></.badge>
              <% else %>
                <.badge style_from_ordinal_value={descriptor.ordinal_value}>
                  <%= descriptor.ordinal_value.name %>
                </.badge>
              <% end %>
              <.markdown
                text={descriptor.descriptor}
                class="prose-sm flex-1 w-full p-2 border border-ltrn-lighter rounded-sm bg-ltrn-lightest"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # lifecycle

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_params, _uri, socket) do
    rubrics = Rubrics.list_full_rubrics()
    results = length(rubrics)

    socket =
      socket
      |> stream(:rubrics, rubrics)
      |> assign(:results, results)

    {:noreply, socket}
  end
end
