defmodule LantternWeb.MenuComponent do
  alias Lanttern.Identity
  use LantternWeb, :live_component

  def mount(socket) do
    active_nav =
      cond do
        socket.view == LantternWeb.DashboardLive ->
          :dashboard

        socket.view in [
          LantternWeb.AssessmentPointsLive,
          LantternWeb.AssessmentPointsExplorerLive,
          LantternWeb.AssessmentPointLive
        ] ->
          :assessment_points

        socket.view in [LantternWeb.CurriculumLive, LantternWeb.CurriculumBNCCEFLive] ->
          :curriculum

        true ->
          nil
      end

    {:ok, assign(socket, :active_nav, active_nav)}
  end

  def update(%{current_user: current_user} = assigns, socket) do
    {type, name, school} =
      case current_user.current_profile.type do
        "student" ->
          {
            "Student",
            current_user.current_profile.student.name,
            current_user.current_profile.student.school.name
          }

        "teacher" ->
          {
            "Teacher",
            current_user.current_profile.teacher.name,
            current_user.current_profile.teacher.school.name
          }
      end

    profiles =
      Identity.list_profiles(
        user_id: current_user.id,
        preloads: [teacher: :school, student: :school]
      )

    socket =
      socket
      |> assign(assigns)
      |> assign(:profile_type, type)
      |> assign(:profile_name, name)
      |> assign(:profile_school, school)
      |> assign(:profiles, profiles)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <button
        type="button"
        class="group flex gap-1 items-center p-2 rounded bg-white shadow-xl hover:bg-slate-100"
        phx-click={JS.exec("data-show", to: "#menu")}
        aria-label="open menu"
      >
        <.icon name="hero-bars-3 text-ltrn-subtle" />
        <div class="w-6 h-6 rounded-full bg-ltrn-mesh-primary blur-sm group-hover:blur-none transition-[filter]" />
      </button>
      <.panel_overlay
        id="menu"
        class="flex items-stretch h-full divide-x divide-ltrn-hairline ltrn-bg-menu"
      >
        <div class="flex-1 flex flex-col justify-between">
          <nav>
            <ul class="grid grid-cols-3 gap-px border-b border-ltrn-hairline bg-ltrn-hairline">
              <.nav_item active={@active_nav == :dashboard} path={~p"/"}>
                Dashboard
              </.nav_item>
              <.nav_item active={@active_nav == :assessment_points} path={~p"/assessment_points"}>
                Assessment points
              </.nav_item>
              <.nav_item active={@active_nav == :curriculum} path={~p"/curriculum"}>
                Curriculum
              </.nav_item>
            </ul>
          </nav>
          <h5 class="relative flex items-center ml-6 mb-6 font-display font-black text-3xl text-ltrn-text">
            <span class="w-20 h-20 rounded-full bg-ltrn-mesh-primary blur-sm" />
            <span class="relative -ml-10">lanttern</span>
          </h5>
        </div>
        <div class="w-96 p-10 font-display overflow-y-auto">
          <p class="mb-4 font-black text-lg text-ltrn-primary">You're logged in as</p>
          <p class="font-black text-4xl text-ltrn-text">
            <%= @profile_name %>
          </p>
          <p class="mt-2 font-black text-lg text-ltrn-text">
            <%= @profile_type %> @ <%= @profile_school %>
          </p>
          <nav class="mt-10">
            <ul class="font-bold text-lg text-ltrn-subtle leading-loose">
              <li :if={@current_user.is_root_admin}>
                <.link href={~p"/admin"} target="_blank" class="underline hover:text-ltrn-text">
                  Admin
                </.link>
              </li>
              <li>
                <button
                  type="button"
                  phx-click={toggle_profile_list()}
                  class="flex items-center gap-2 underline hover:text-ltrn-text"
                >
                  Change profile <.icon name="hero-chevron-down" id="profile-list-down-icon" />
                  <.icon name="hero-chevron-up" id="profile-list-up-icon" class="hidden" />
                </button>
                <ul id="profile-list" class="hidden mt-2 mb-4 divide-y divide-ltrn-hairline">
                  <.profile_item
                    :for={profile <- @profiles}
                    profile={profile}
                    current_profile_id={@current_user.current_profile_id}
                  />
                </ul>
              </li>
              <%!-- <li>Edit profile</li> --%>
              <li class="mt-4">
                <.link
                  href={~p"/users/log_out"}
                  method="delete"
                  class="underline hover:text-ltrn-text"
                >
                  Log out
                </.link>
              </li>
            </ul>
          </nav>
        </div>
      </.panel_overlay>
    </div>
    """
  end

  attr :path, :string, required: true
  attr :active, :boolean, required: true
  slot :inner_block, required: true

  def nav_item(assigns) do
    ~H"""
    <li class="bg-white">
      <.link
        navigate={@path}
        class={[
          "group relative block p-10 font-display font-black text-lg",
          if(@active, do: "text-ltrn-text", else: "text-ltrn-subtle underline hover:text-ltrn-text")
        ]}
      >
        <span class={[
          "absolute top-2 left-2 block w-6 h-6",
          if(@active, do: "bg-ltrn-primary", else: "group-hover:bg-ltrn-subtle")
        ]} />
        <%= render_slot(@inner_block) %>
      </.link>
    </li>
    """
  end

  attr :current_profile_id, :string, required: true
  attr :profile, Lanttern.Identity.Profile, required: true

  def profile_item(%{profile: profile, current_profile_id: current_profile_id} = assigns) do
    {id, type, name, school} =
      case profile.type do
        "student" ->
          {
            profile.id,
            "Student",
            profile.student.name,
            profile.student.school.name
          }

        "teacher" ->
          {
            profile.id,
            "Teacher",
            profile.teacher.name,
            profile.teacher.school.name
          }
      end

    active = id == current_profile_id

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:type, type)
      |> assign(:name, name)
      |> assign(:school, school)
      |> assign(:active, active)

    ~H"""
    <li id={"profile-#{@id}"}>
      <button
        type="button"
        class="group flex items-center gap-2 w-full py-2 text-left text-ltrn-subtle leading-none"
      >
        <.icon
          name="hero-check-circle"
          class={
            if(@active,
              do: "text-ltrn-primary",
              else: "text-transparent group-hover:text-ltrn-subtle"
            )
          }
        />
        <div>
          <span class={[
            "block font-bold text-sm",
            if(@active, do: "text-ltrn-text")
          ]}>
            <%= @name %>
          </span>
          <span class="font-sans font-normal text-xs">
            <%= @type %> @ <%= @school %>
          </span>
        </div>
      </button>
    </li>
    """
  end

  def toggle_profile_list(js \\ %JS{}) do
    js
    |> JS.toggle(to: "#profile-list")
    |> JS.toggle(to: "#profile-list-down-icon")
    |> JS.toggle(to: "#profile-list-up-icon")
  end
end
