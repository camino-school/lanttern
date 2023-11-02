defmodule LantternWeb.RubricsLive.Explorer do
  use LantternWeb, :live_view

  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric

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
        <.link
          class="shrink-0 flex items-center gap-2 text-sm text-ltrn-subtle hover:underline"
          patch={~p"/rubrics/new"}
        >
          Create rubric <.icon name="hero-plus-mini" class="text-ltrn-primary" />
        </.link>
      </div>
      <div id="rubrics-list" phx-update="stream">
        <div
          :for={{dom_id, rubric} <- @streams.rubrics}
          class="w-full p-6 mt-4 rounded shadow-xl bg-white"
          id={dom_id}
        >
          <div class="flex items-start justify-between mb-4">
            <div class="flex-1">
              <p class="flex items-center gap-2">
                <.badge>#<%= rubric.id %></.badge>
                <span class="font-display font-black text-lg">Criteria: <%= rubric.criteria %></span>
              </p>
              <div class="flex items-center gap-4 mt-4 text-base">
                <.icon name="hero-view-columns" class="shrink-0 text-rose-500" /> <%= rubric.scale.name %>
              </div>
            </div>
            <div class="shrink-0 flex items-center gap-2">
              <.badge :if={rubric.is_differentiation} theme="secondary">Differentiation</.badge>
              <.link patch={~p"/rubrics/#{rubric}/edit"} class={get_button_styles("ghost")}>
                Edit
              </.link>
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
    <.slide_over
      :if={@live_action in [:new, :edit]}
      id="rubric-form-overlay"
      show={true}
      prevent_close_on_click_away
    >
      <:title><%= @overlay_title %></:title>
      <.live_component
        module={LantternWeb.RubricsLive.FormComponent}
        id={@rubric.id || :new}
        action={@live_action}
        rubric={@rubric}
        patch={~p"/rubrics"}
      />
      <:actions_left>
        <.button
          type="button"
          theme="ghost"
          phx-click={
            JS.patch(~p"/rubrics")
            |> JS.push("delete", value: %{id: @rubric.id})
          }
          data-confirm="Are you sure?"
        >
          Delete
        </.button>
      </:actions_left>
      <:actions>
        <.button type="button" theme="ghost" phx-click={JS.patch(~p"/rubrics")}>
          Cancel
        </.button>
        <.button type="submit" form="rubric-form" phx-disable-with="Saving...">
          Save
        </.button>
      </:actions>
    </.slide_over>
    """
  end

  # lifecycle

  def mount(_params, _session, socket) do
    rubrics = Rubrics.list_full_rubrics()
    results = length(rubrics)

    socket =
      socket
      |> stream(:rubrics, rubrics)
      |> assign(:results, results)

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:overlay_title, "Edit rubric")
    |> assign(:rubric, Rubrics.get_rubric!(id, preloads: :descriptors))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:overlay_title, "Create Rubric")
    |> assign(:rubric, %Rubric{})
  end

  defp apply_action(socket, :index, _params), do: socket

  # event handlers

  def handle_event("delete", %{"id" => id}, socket) do
    rubric = Rubrics.get_rubric!(id)
    {:ok, _} = Rubrics.delete_rubric(rubric)

    {:noreply, stream_delete(socket, :rubrics, rubric)}
  end
end
