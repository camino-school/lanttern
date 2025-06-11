defmodule LantternWeb.MomentPageComponent do
  @moduledoc """
  Moment details page "layout".

  `render/1` function component will render the shared structure (breadcrumbs,
  tabs rendering, classes overlay, moment edit modal).

  The `on_mount/4` hook will manage the shared state (strand, moment, and classes loading)
  and attach handlers related to this shared state (e.g. moment edit).
  """

  use Phoenix.Component

  import Phoenix.LiveView
  use Gettext, backend: Lanttern.Gettext

  alias Phoenix.LiveView.JS

  use Phoenix.VerifiedRoutes,
    endpoint: LantternWeb.Endpoint,
    router: LantternWeb.Router,
    statics: LantternWeb.static_paths()

  import LantternWeb.CoreComponents
  import LantternWeb.NeoComponents
  import LantternWeb.NavigationComponents
  import LantternWeb.OverlayComponents

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.Strand

  # shared components
  alias LantternWeb.LearningContext.MomentFormComponent
  import LantternWeb.LearningContextComponents, only: [mini_strand_card: 1]
  import LantternWeb.FiltersHelpers, only: [assign_strand_classes_filter: 1]

  # render

  attr :current_user, :any, required: true
  attr :strand, :any, required: true
  attr :moment, :any, required: true
  attr :live_action, :any, required: true
  attr :selected_classes, :any, required: true
  attr :params, :any, required: true
  attr :current_path, :any, required: true
  attr :classes, :any, required: true
  attr :selected_classes_ids, :any, required: true
  attr :select_classes_overlay_title, :any, required: true
  attr :select_classes_overlay_navigate, :any, required: true

  slot :inner_block, required: true

  def render(assigns) do
    ~H"""
    <div id="moment-page">
      <.header_nav current_user={@current_user}>
        <:breadcrumb navigate={~p"/strands"}><%= gettext("Strands") %></:breadcrumb>
        <:breadcrumb is_info>
          <.mini_strand_card strand={@strand} class="w-60" />
        </:breadcrumb>
        <:breadcrumb navigate={~p"/strands/#{@strand}/moments"} title={@strand.name}>
          <%= @strand.name %>
        </:breadcrumb>
        <:title><%= gettext("Moment: %{moment}", moment: @moment.name) %></:title>
        <div class="flex items-center justify-between gap-4 px-4">
          <.neo_tabs id="moment-nav-tabs">
            <:tab patch={~p"/strands/moment/#{@moment}"} is_current={@live_action == :show}>
              <%= gettext("Overview") %>
            </:tab>
            <:tab
              patch={~p"/strands/moment/#{@moment}/assessment"}
              is_current={@live_action == :assessment}
            >
              <%= gettext("Moment assessment") %>
            </:tab>
            <:tab patch={~p"/strands/moment/#{@moment}/quizzes"} is_current={@live_action == :quizzes}>
              <%= gettext("Quizzes") %>
            </:tab>
            <:tab patch={~p"/strands/moment/#{@moment}/cards"} is_current={@live_action == :cards}>
              <%= gettext("Cards") %>
            </:tab>
            <:tab patch={~p"/strands/moment/#{@moment}/notes"} is_current={@live_action == :notes}>
              <%= gettext("Notes") %>
            </:tab>
          </.neo_tabs>
          <div class="flex items-center gap-4">
            <.action
              type="button"
              phx-click={JS.exec("data-show", to: "#strand-classes-filter-modal")}
              icon_name="hero-users-mini"
            >
              <%= format_action_items_text(
                @selected_classes,
                gettext("No class selected")
              ) %>
            </.action>
            <.action
              type="link"
              patch={"#{@current_path}?is_editing=true"}
              icon_name="hero-pencil-mini"
            >
              <%= gettext("Edit moment") %>
            </.action>
            <.menu_button id="strand-menu-more">
              <:item
                id={"remove-moment-#{@moment.id}"}
                text={gettext("Delete moment")}
                theme="alert"
                on_click={JS.push("delete_moment")}
                confirm_msg={gettext("Are you sure?")}
              />
            </.menu_button>
          </div>
        </div>
      </.header_nav>
      <%= render_slot(@inner_block) %>
      <.slide_over
        :if={@params["is_editing"] == "true"}
        id="moment-form-overlay"
        show={true}
        on_cancel={JS.patch(@current_path)}
      >
        <:title><%= gettext("Edit moment") %></:title>
        <.live_component
          module={MomentFormComponent}
          id={@moment.id}
          moment={@moment}
          patch={@current_path}
          notify_parent
        />
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#moment-form-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="moment-form">
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
      <.live_component
        module={LantternWeb.Filters.ClassesFilterOverlayComponent}
        id="strand-classes-filter-modal"
        current_user={@current_user}
        title={@select_classes_overlay_title}
        profile_filter_opts={[strand_id: @strand.id]}
        classes={@classes}
        selected_classes_ids={@selected_classes_ids}
        navigate={@select_classes_overlay_navigate}
      />
    </div>
    """
  end

  # on_mount

  def on_mount(:default, params, _session, socket) do
    socket =
      socket
      |> assign_moment(params)
      |> assign_strand()
      |> assign_strand_classes_filter()
      |> attach_hook(:moment_page_handle_params, :handle_params, &handle_params/3)
      |> attach_hook(:moment_page_handle_event, :handle_event, &handle_event/3)
      |> attach_hook(:moment_page_handle_info, :handle_info, &handle_info/2)

    {:cont, socket}
  end

  defp assign_moment(%{assigns: %{moment: %Moment{}}} = socket, _params), do: socket

  defp assign_moment(socket, %{"id" => id}) do
    case LearningContext.get_moment(id, preloads: :subjects) do
      moment when is_nil(moment) ->
        socket
        |> put_flash(:error, gettext("Couldn't find moment"))
        |> redirect(to: ~p"/strands")

      moment ->
        socket
        |> assign(:moment, moment)
    end
  end

  defp assign_strand(%{assigns: %{strand: %Strand{}}} = socket), do: socket

  defp assign_strand(socket) do
    strand =
      LearningContext.get_strand(socket.assigns.moment.strand_id,
        preloads: [:subjects, :years]
      )

    socket
    |> assign(:strand, strand)
    |> assign(:page_title, "#{socket.assigns.moment.name} • #{strand.name}")
  end

  # handle_params

  defp handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)

    {:cont, socket}
  end

  # event handlers

  defp handle_event("delete_moment", _params, socket) do
    case LearningContext.delete_moment(socket.assigns.moment) do
      {:ok, _moment} ->
        socket =
          socket
          |> put_flash(:info, gettext("Moment deleted"))
          |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}/moments")

        {:halt, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(
            :error,
            gettext("Moment has linked assessments. Deleting it would cause some data loss.")
          )

        {:halt, socket}
    end
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  # info handlers

  defp handle_info({MomentFormComponent, {:saved, moment}}, socket) do
    {:halt, assign(socket, :moment, moment)}
  end

  defp handle_info(_, socket), do: {:cont, socket}
end
