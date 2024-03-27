defmodule LantternWeb.MenuComponent do
  use LantternWeb, :live_component

  alias Lanttern.Identity

  def render(assigns) do
    ~H"""
    <div>
      <.panel_overlay
        id="menu"
        class="flex items-stretch h-full divide-x divide-ltrn-lighter ltrn-bg-menu"
      >
        <div class="flex-1 flex flex-col justify-between">
          <nav>
            <ul
              :if={@current_profile.type == "teacher"}
              class="grid grid-cols-3 gap-px border-b border-ltrn-lighter bg-ltrn-lighter"
            >
              <.nav_item active={@active_nav == :dashboard} path={~p"/dashboard"}>
                <%= gettext("Dashboard") %>
              </.nav_item>
              <.nav_item active={@active_nav == :strands} path={~p"/strands"}>
                <%= gettext("Strands") %>
              </.nav_item>
              <.nav_item active={@active_nav == :school} path={~p"/school"}>
                <%= gettext("School") %>
              </.nav_item>
              <.nav_item active={@active_nav == :assessment_points} path={~p"/assessment_points"}>
                <%= gettext("Assessment points") %>
              </.nav_item>
              <.nav_item active={@active_nav == :rubrics} path={~p"/rubrics"}>
                <%= gettext("Rubrics") %>
              </.nav_item>
              <.nav_item active={@active_nav == :curriculum} path={~p"/curriculum"}>
                <%= gettext("Curriculum") %>
              </.nav_item>
              <.nav_item active={@active_nav == :report_cards} path={~p"/report_cards"}>
                <%= gettext("Report cards") %>
              </.nav_item>
              <.nav_item active={@active_nav == :grading} path={~p"/grading"}>
                <%= gettext("Grading") %>
              </.nav_item>
              <%!-- use this li as placeholder when nav items % 3 != 0--%>
              <li class="bg-white"></li>
            </ul>
            <ul
              :if={@current_profile.type == "student"}
              class="grid grid-cols-3 gap-px border-b border-ltrn-lighter bg-ltrn-lighter"
            >
              <.nav_item active={@active_nav == :dashboard} path={~p"/student"}>
                <%= gettext("Home") %>
              </.nav_item>
              <%!-- use this li as placeholder when nav items % 3 != 0--%>
              <li class="bg-white"></li>
              <li class="bg-white"></li>
            </ul>
            <ul
              :if={@current_profile.type == "guardian"}
              class="grid grid-cols-3 gap-px border-b border-ltrn-lighter bg-ltrn-lighter"
            >
              <.nav_item active={@active_nav == :dashboard} path={~p"/guardian"}>
                <%= gettext("Home") %>
              </.nav_item>
              <%!-- use this li as placeholder when nav items % 3 != 0--%>
              <li class="bg-white"></li>
              <li class="bg-white"></li>
            </ul>
          </nav>
          <h5 class="relative flex items-center ml-6 mb-6 font-display font-black text-3xl text-ltrn-dark">
            <span class="w-20 h-20 rounded-full bg-ltrn-mesh-primary blur-sm" />
            <span class="relative -ml-10">Lanttern</span>
          </h5>
        </div>
        <div class="flex flex-col w-96 p-10 font-display overflow-y-auto">
          <p class="mb-4 font-black text-lg text-ltrn-primary">
            <%= gettext("You're logged in as") %>
          </p>
          <p class="font-black text-4xl text-ltrn-dark">
            <%= @current_profile.name %>
          </p>
          <p class="mt-2 font-black text-lg text-ltrn-dark">
            <%= Gettext.dgettext(
              LantternWeb.Gettext,
              "schools",
              String.capitalize(@current_profile.type)
            ) %> @ <%= @current_profile.school_name %>
          </p>
          <nav class="mt-10">
            <ul class="font-bold text-lg text-ltrn-subtle leading-loose">
              <li :if={@current_user.is_root_admin}>
                <.link
                  href={~p"/admin"}
                  class="flex items-center gap-2 underline hover:text-ltrn-dark"
                >
                  Admin
                </.link>
              </li>
              <li>
                <button
                  type="button"
                  phx-click={toggle_profile_list()}
                  class="flex items-center gap-2 underline hover:text-ltrn-dark"
                >
                  <%= gettext("Change profile") %>
                  <.icon name="hero-chevron-down" id="profile-list-down-icon" />
                  <.icon name="hero-chevron-up" id="profile-list-up-icon" class="hidden" />
                </button>
                <ul id="profile-list" class="hidden mt-2 mb-4 divide-y divide-ltrn-lighter">
                  <.profile_item
                    :for={profile <- @profiles}
                    profile={profile}
                    current_profile_id={@current_user.current_profile_id}
                    phx-click="change_profile"
                    phx-target={@myself}
                    phx-value-userid={@current_user.id}
                    phx-value-profileid={profile.id}
                  />
                </ul>
              </li>
              <%!-- <li>Edit profile</li> --%>
              <li class="mt-4">
                <.link
                  href={~p"/users/log_out"}
                  method="delete"
                  class="underline hover:text-ltrn-dark"
                >
                  <%= gettext("Log out") %>
                </.link>
              </li>
            </ul>
          </nav>
          <span class="flex-1" />
          <div class="flex items-center gap-4 font-bold text-sm text-ltrn-subtle leading-loose">
            <span><%= gettext("Language:") %></span>
            <.lang_button
              is_current={@current_user.current_profile.current_locale == "en"}
              phx-click="set_locale"
              phx-value-locale="en"
              phx-target={@myself}
            >
              EN
            </.lang_button>
            <.lang_button
              is_current={@current_user.current_profile.current_locale == "pt_BR"}
              phx-click="set_locale"
              phx-value-locale="pt_BR"
              phx-target={@myself}
            >
              PT-BR
            </.lang_button>
          </div>
          <.error_block
            :if={@locale_error}
            on_dismiss={JS.push("dismiss_locale_error", target: @myself)}
            class="mt-4"
          >
            <%= @locale_error %>
          </.error_block>
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
        patch={@path}
        class={[
          "group relative block p-10 font-display font-black text-lg",
          if(@active, do: "text-ltrn-dark", else: "text-ltrn-subtle underline hover:text-ltrn-dark")
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
  attr :rest, :global, doc: "use to pass phx-* bindings to change profile button"

  def profile_item(%{profile: profile, current_profile_id: current_profile_id} = assigns) do
    {name, school} =
      case profile.type do
        "student" ->
          {
            profile.student.name,
            profile.student.school.name
          }

        "teacher" ->
          {
            profile.teacher.name,
            profile.teacher.school.name
          }

        "guardian" ->
          {
            "#{gettext("Guardian of")} #{profile.guardian_of_student.name}",
            profile.guardian_of_student.school.name
          }
      end

    assigns =
      assigns
      |> assign(:name, name)
      |> assign(:school, school)
      |> assign(:active, profile.id == current_profile_id)

    ~H"""
    <li id={"profile-#{@profile.id}"}>
      <button
        type="button"
        class="group flex items-center gap-2 w-full py-2 text-left text-ltrn-subtle leading-none"
        {@rest}
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
            if(@active, do: "text-ltrn-dark")
          ]}>
            <%= @name %>
          </span>
          <span class="font-sans font-normal text-xs">
            <%= Gettext.dgettext(LantternWeb.Gettext, "schools", String.capitalize(@profile.type)) %> @ <%= @school %>
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

  attr :is_current, :boolean, required: true
  attr :rest, :global, doc: "use to pass phx-* bindings to change profile button"
  slot :inner_block, required: true

  def lang_button(assigns) do
    ~H"""
    <button
      type="button"
      class={if(@is_current, do: "text-ltrn-dark", else: "hover:underline")}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  # lifecycle

  def mount(socket) do
    active_nav =
      cond do
        socket.view == LantternWeb.DashboardLive ->
          :dashboard

        socket.view in [
          LantternWeb.StrandsLive,
          LantternWeb.StrandLive,
          LantternWeb.MomentLive
        ] ->
          :strands

        socket.view in [
          LantternWeb.SchoolLive,
          LantternWeb.ClassLive,
          LantternWeb.StudentLive
        ] ->
          :school

        socket.view in [
          LantternWeb.AssessmentPointsLive,
          LantternWeb.AssessmentPointLive
        ] ->
          :assessment_points

        socket.view in [
          LantternWeb.RubricsLive
        ] ->
          :rubrics

        socket.view in [
          LantternWeb.CurriculaLive,
          LantternWeb.CurriculumLive,
          LantternWeb.CurriculumComponentLive,
          LantternWeb.CurriculumBNCCEFLive
        ] ->
          :curriculum

        socket.view in [LantternWeb.ReportCardsLive, LantternWeb.ReportCardLive] ->
          :report_cards

        socket.view in [LantternWeb.GradesReportsLive] ->
          :grading

        true ->
          nil
      end

    socket =
      socket
      |> assign(:locale_error, nil)
      |> assign(:active_nav, active_nav)

    {:ok, socket}
  end

  def update(%{current_user: current_user} = assigns, socket) do
    profiles =
      Identity.list_profiles(
        user_id: current_user.id,
        preloads: [teacher: :school, student: :school, guardian_of_student: :school]
      )

    socket =
      socket
      |> assign(assigns)
      |> assign(:current_profile, current_user.current_profile)
      |> assign(:profiles, profiles)

    {:ok, socket}
  end

  # event handlers

  def handle_event("change_profile", %{"userid" => user_id, "profileid" => profile_id}, socket) do
    user = Identity.get_user!(user_id)
    Identity.update_user_current_profile_id(user, profile_id)

    {:noreply, push_navigate(socket, to: socket.assigns.current_path, replace: true)}
  end

  def handle_event("set_locale", %{"locale" => locale}, socket) do
    Identity.update_profile(
      socket.assigns.current_user.current_profile,
      %{current_locale: locale}
    )
    |> case do
      {:ok, _profile} ->
        {:noreply, redirect(socket, to: socket.assigns.current_path)}

      {:error, %Ecto.Changeset{errors: [current_locale: {error_msg, _}]}} ->
        {:noreply, assign(socket, :locale_error, error_msg)}

      {:error, _} ->
        {:noreply, assign(socket, :locale_error, "Something went wrong")}
    end
  end

  def handle_event("dismiss_locale_error", _params, socket) do
    {:noreply, assign(socket, :locale_error, nil)}
  end
end
