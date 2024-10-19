defmodule LantternWeb.MenuComponent do
  @moduledoc """
  Shared menu components
  """

  use LantternWeb, :live_component

  alias Lanttern.Identity

  def render(assigns) do
    ~H"""
    <div>
      <.panel_overlay
        id="menu"
        class={[
          "h-full overflow-y-auto ltrn-bg-menu",
          "md:flex md:items-stretch md:divide-x md:divide-ltrn-lighter"
        ]}
      >
        <div class="md:flex-1 md:flex md:flex-col-reverse md:justify-between">
          <div class="p-6">
            <h5 class="relative flex items-center font-display font-black text-3xl text-ltrn-dark">
              <span class="w-20 h-20 rounded-full bg-ltrn-mesh-primary blur-sm" />
              <span class="relative -ml-10">Lanttern</span>
            </h5>
          </div>
          <nav>
            <ul class={[
              "grid grid-cols-2 gap-px border-y border-ltrn-lighter bg-ltrn-lighter",
              "lg:grid-cols-3 md:border-t-0"
            ]}>
              <.nav_item
                :for={nav_item <- @profile_nav_items}
                active={@active_nav == nav_item.active}
                path={nav_item.path}
              >
                <%= nav_item.text %>
              </.nav_item>
              <%!-- use this li as placeholder when nav rem(items, 3) != 0 (sm) or rem(items, 2) != 0 --%>
              <li :if={@has_sm_nav_item_placeholder} class="lg:hidden bg-white"></li>
              <li :if={@lg_nav_item_placeholders_count > 0} class="hidden lg:block bg-white"></li>
              <li :if={@lg_nav_item_placeholders_count == 2} class="hidden lg:block bg-white"></li>
            </ul>
          </nav>
        </div>
        <div class={[
          "p-10 font-display overflow-y-auto",
          "md:flex md:flex-col md:w-80 lg:w-96"
        ]}>
          <p class="mb-4 font-black text-lg text-ltrn-primary">
            <%= gettext("You're logged in as") %>
          </p>
          <p class="font-black text-4xl text-ltrn-dark">
            <%= @current_user.current_profile.name %>
          </p>
          <p class="mt-2 font-black text-lg text-ltrn-dark">
            <%= Gettext.dgettext(
              LantternWeb.Gettext,
              "schools",
              String.capitalize(@current_user.current_profile.type)
            ) %> @ <%= @current_user.current_profile.school_name %>
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
                    phx-click={
                      JS.push(
                        "change_profile",
                        value: %{
                          "user_id" => @current_user.id,
                          "profile_id" => profile.id,
                          "profile_type" => profile.type
                        },
                        target: @myself
                      )
                    }
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
          <span class="hidden sm:block sm:flex-1" />
          <div class="flex items-center gap-4 mt-6 font-bold text-sm text-ltrn-subtle leading-loose">
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
          <div class="mt-4">
            <a
              href="/docs/politica-de-privacidade-lanttern-20240403.pdf"
              target="_blank"
              class="mt-4 text-sm font-display font-bold text-ltrn-subtle hover:underline"
            >
              <%= gettext("Privacy policy") %>
            </a>
            <br />
            <a
              href="/docs/termos-de-uso-lanttern-20240403.pdf"
              target="_blank"
              class="mt-4 text-sm font-display font-bold text-ltrn-subtle hover:underline"
            >
              <%= gettext("Terms of service") %>
            </a>
          </div>
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
          "group relative block p-6 font-display font-black text-base",
          "md:p-10 lg:text-lg",
          if(@active, do: "text-ltrn-dark", else: "text-ltrn-subtle underline hover:text-ltrn-dark")
        ]}
      >
        <span class={[
          "absolute top-2 left-2 block w-4 h-4 rounded-full",
          "md:w-6 md:h-6",
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
            profile.guardian_of_student.name,
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

  @view_to_nav_map %{
    LantternWeb.DashboardLive => :dashboard,

    # strands
    LantternWeb.StrandsLive => :strands,
    LantternWeb.StrandLive => :strands,
    LantternWeb.MomentLive => :strands,

    # students records
    LantternWeb.StudentsRecordsLive => :students_records,
    LantternWeb.StudentRecordLive => :students_records,

    # school
    LantternWeb.SchoolLive => :school,
    LantternWeb.ClassLive => :school,
    LantternWeb.StudentLive => :school,

    # assessment points
    LantternWeb.AssessmentPointsLive => :assessment_points,
    LantternWeb.AssessmentPointLive => :assessment_points,

    # rubrics
    LantternWeb.RubricsLive => :rubrics,

    # curriculum
    LantternWeb.CurriculaLive => :curriculum,
    LantternWeb.CurriculumLive => :curriculum,
    LantternWeb.CurriculumComponentLive => :curriculum,
    LantternWeb.CurriculumBNCCEFLive => :curriculum,

    # report cards
    LantternWeb.ReportCardsLive => :report_cards,
    LantternWeb.ReportCardLive => :report_cards,

    # grades reports
    LantternWeb.GradesReportsLive => :grades_reports,
    LantternWeb.GradesReportLive => :grades_reports,

    # guardian home
    LantternWeb.GuardianHomeLive => :student_report_card,

    # student home
    LantternWeb.StudentHomeLive => :student_report_card,

    # student report card
    LantternWeb.StudentReportCardLive => :student_report_card,
    LantternWeb.StudentReportCardStrandReportLive => :student_report_card,

    # student strands
    LantternWeb.StudentStrandsLive => :student_strands,
    LantternWeb.StudentStrandReportLive => :student_strands
  }

  def mount(socket) do
    active_nav = Map.get(@view_to_nav_map, socket.view)

    socket =
      socket
      |> assign(:locale_error, nil)
      |> assign(:active_nav, active_nav)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_profiles()
      |> assign_nav_items()

    {:ok, socket}
  end

  defp assign_profiles(socket) do
    profiles =
      Identity.list_profiles(
        user_id: socket.assigns.current_user.id,
        preloads: [teacher: :school, student: :school, guardian_of_student: :school]
      )

    assign(socket, :profiles, profiles)
  end

  defp assign_nav_items(socket) do
    all_nav_items = [
      # staff
      %{profile: "teacher", active: :dashboard, path: ~p"/dashboard", text: gettext("Dashboard")},
      %{profile: "teacher", active: :strands, path: ~p"/strands", text: gettext("Strands")},
      %{
        profile: "teacher",
        active: :students_records,
        path: ~p"/students_records",
        text: gettext("Students records"),
        permission: "wcd"
      },
      %{profile: "teacher", active: :school, path: ~p"/school", text: gettext("School")},
      %{profile: "teacher", active: :rubrics, path: ~p"/rubrics", text: gettext("Rubrics")},
      %{
        profile: "teacher",
        active: :curriculum,
        path: ~p"/curriculum",
        text: gettext("Curriculum")
      },
      %{
        profile: "teacher",
        active: :report_cards,
        path: ~p"/report_cards",
        text: gettext("Report cards")
      },
      %{
        profile: "teacher",
        active: :grades_reports,
        path: ~p"/grades_reports",
        text: gettext("Grades reports")
      },
      # student
      %{
        profile: "student",
        active: :student_report_card,
        path: ~p"/student",
        text: gettext("Report cards")
      },
      %{
        profile: "student",
        active: :student_strands,
        path: ~p"/student_strands",
        text: gettext("Strands")
      },
      # guardian
      %{
        profile: "guardian",
        active: :student_report_card,
        path: ~p"/guardian",
        text: gettext("Report cards")
      }
    ]

    profile_nav_items =
      filter_profile_nav_items(socket.assigns.current_user.current_profile, all_nav_items)

    has_sm_nav_item_placeholder = rem(length(profile_nav_items), 2) == 1

    lg_nav_item_placeholders_count =
      case rem(length(profile_nav_items), 3) do
        1 -> 2
        2 -> 1
        _ -> 0
      end

    socket
    |> assign(:profile_nav_items, profile_nav_items)
    |> assign(:lg_nav_item_placeholders_count, lg_nav_item_placeholders_count)
    |> assign(:has_sm_nav_item_placeholder, has_sm_nav_item_placeholder)
  end

  defp filter_profile_nav_items(profile, all_nav_items, profile_nav_items \\ [])

  defp filter_profile_nav_items(_profile, [], profile_nav_items), do: profile_nav_items

  defp filter_profile_nav_items(profile, [cur_nav_item | other_nav_items], profile_nav_items) do
    add_item? =
      cur_nav_item.profile == profile.type &&
        (is_nil(cur_nav_item[:permission]) || cur_nav_item.permission in profile.permissions)

    profile_nav_items =
      if add_item?, do: profile_nav_items ++ [cur_nav_item], else: profile_nav_items

    filter_profile_nav_items(profile, other_nav_items, profile_nav_items)
  end

  # event handlers

  def handle_event(
        "change_profile",
        %{"user_id" => user_id, "profile_id" => profile_id, "profile_type" => profile_type},
        socket
      ) do
    user = Identity.get_user!(user_id)

    Identity.update_user_current_profile_id(user, profile_id)

    # redirect to profile home on profile change
    # (avoid 404 when permissions are checked on view mount)
    to_path =
      case profile_type do
        "teacher" -> ~p"/dashboard"
        "student" -> ~p"/student"
        "guardian" -> ~p"/guardian"
      end

    {:noreply, push_navigate(socket, to: to_path, replace: true)}
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
