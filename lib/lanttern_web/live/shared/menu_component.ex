defmodule LantternWeb.MenuComponent do
  @moduledoc """
  Shared menu components
  """

  alias Lanttern.Personalization
  alias Lanttern.Schools
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
              <span class="w-20 h-20 rounded-full bg-ltrn-mesh-primary blur-xs" />
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
          <.profile_picture
            picture_url={@current_user.current_profile.profile_picture_url}
            profile_name={@current_user.current_profile.name}
            size="lg"
            class="mb-4"
          />
          <p class="font-black text-4xl text-ltrn-dark">
            <%= @current_user.current_profile.name %>
          </p>
          <div id="profile-select" class="group mt-2">
            <button
              type="button"
              phx-click={toggle_profile_list(@myself)}
              class="flex items-center gap-2 font-black text-lg text-left hover:text-ltrn-subtle"
            >
              <%= Gettext.dgettext(
                Lanttern.Gettext,
                "schools",
                @current_user.current_profile.role ||
                  String.capitalize(@current_user.current_profile.type)
              ) %> @ <%= @current_user.current_profile.school_name %>

              <.icon name="hero-chevron-down" id="profile-list-down-icon" />
              <.icon name="hero-chevron-up" id="profile-list-up-icon" class="hidden" />
            </button>
            <div
              :if={!@profiles_loaded}
              class="hidden items-center gap-2 mt-2 group-phx-click-loading:flex"
            >
              <.spinner />
              <%= gettext("Loading profiles") %>
            </div>
            <div id="profile-list" class="hidden">
              <ul
                id="profile-list-ul"
                class="mt-2 mb-4 divide-y divide-ltrn-lighter"
                phx-update="stream"
              >
                <.profile_item
                  :for={{dom_id, profile} <- @streams.profiles}
                  id={dom_id}
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
            </div>
          </div>
          <div id="cycle-select" class="group mt-2">
            <button
              type="button"
              phx-click={toggle_cycle_list(@myself)}
              class="flex items-center gap-2 font-black text-lg hover:text-ltrn-subtle"
            >
              <%= if @current_user.current_profile.current_school_cycle,
                do: "#{gettext("Cycle")}: #{@current_user.current_profile.current_school_cycle.name}",
                else: gettext("No cycle selected") %>
              <.icon name="hero-chevron-down" id="cycle-list-down-icon" />
              <.icon name="hero-chevron-up" id="cycle-list-up-icon" class="hidden" />
            </button>
            <div
              :if={!@has_school_cycles}
              class="hidden items-center gap-2 mt-2 group-phx-click-loading:flex"
            >
              <.spinner />
              <%= gettext("Loading cycles") %>
            </div>
            <div id="cycle-list" class="hidden">
              <%= if @has_school_cycles do %>
                <ul id="cycle-list-ul" class="flex flex-wrap gap-2 mt-2" phx-update="stream">
                  <.badge_button
                    :for={{dom_id, cycle} <- @streams.school_cycles}
                    id={dom_id}
                    is_checked={
                      cycle.id == Map.get(@current_user.current_profile.current_school_cycle, :id)
                    }
                    phx-click={
                      JS.push("select_school_cycle", value: %{"id" => cycle.id}, target: @myself)
                    }
                  >
                    <%= cycle.name %>
                  </.badge_button>
                </ul>
              <% else %>
                <.empty_state_simple class="mt-2 group-phx-click-loading:hidden">
                  <%= gettext("No cycles registered") %>
                </.empty_state_simple>
              <% end %>
            </div>
          </div>
          <nav class="mt-10">
            <ul class="font-bold text-lg text-ltrn-subtle leading-loose">
              <li :if={@current_user.current_profile.type == "staff"}>
                <.link
                  href={~p"/school/staff/#{@current_user.current_profile.staff_member_id}"}
                  class="flex items-center gap-2 hover:text-ltrn-dark"
                >
                  <%= gettext("My area") %>
                </.link>
              </li>
              <li :if={@current_user.is_root_admin}>
                <.link href={~p"/admin"} class="flex items-center gap-2 hover:text-ltrn-dark">
                  <%= gettext("Admin") %>
                </.link>
              </li>
              <li>
                <.link href={~p"/users/log_out"} method="delete" class="hover:text-ltrn-dark">
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
          if(@active, do: "text-ltrn-dark", else: "text-ltrn-subtle hover:text-ltrn-dark")
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

  attr :id, :string, required: true
  attr :current_profile_id, :string, required: true
  attr :profile, Lanttern.Identity.Profile, required: true
  attr :rest, :global, doc: "use to pass phx-* bindings to change profile button"

  def profile_item(%{profile: profile, current_profile_id: current_profile_id} = assigns) do
    assigns =
      assigns
      |> assign(:active, profile.id == current_profile_id)

    ~H"""
    <li id={@id}>
      <button
        type="button"
        class="group/item flex items-center gap-2 w-full py-2 text-left text-ltrn-subtle leading-none"
        {@rest}
      >
        <.icon
          name="hero-check-circle"
          class={
            if(@active,
              do: "text-ltrn-primary",
              else: "text-ltrn-subtle group-hover/item:text-ltrn-dark"
            )
          }
        />
        <div>
          <span class={[
            "block font-bold text-sm",
            if(@active, do: "text-ltrn-dark", else: "group-hover/item:text-ltrn-dark")
          ]}>
            <%= @profile.name %>
          </span>
          <span class="font-sans font-normal text-xs">
            <%= Gettext.dgettext(
              Lanttern.Gettext,
              "schools",
              @profile.role || String.capitalize(@profile.type)
            ) %> @ <%= @profile.school_name %>
          </span>
        </div>
      </button>
    </li>
    """
  end

  def toggle_cycle_list(js \\ %JS{}, myself) do
    js
    |> JS.toggle(to: "#cycle-list")
    |> JS.toggle(to: "#cycle-list-down-icon")
    |> JS.toggle(to: "#cycle-list-up-icon")
    |> JS.push("stream_school_cycles", target: myself, loading: "#cycle-select")
  end

  def toggle_profile_list(js \\ %JS{}, myself) do
    js
    |> JS.toggle(to: "#profile-list")
    |> JS.toggle(to: "#profile-list-down-icon")
    |> JS.toggle(to: "#profile-list-up-icon")
    |> JS.push("stream_user_profiles", target: myself, loading: "#profile-select")
  end

  attr :is_current, :boolean, required: true
  attr :rest, :global, doc: "use to pass phx-* bindings to change profile button"
  slot :inner_block, required: true

  def lang_button(assigns) do
    ~H"""
    <button
      type="button"
      class={if(@is_current, do: "text-ltrn-dark", else: "hover:text-ltrn-dark")}
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
    LantternWeb.StrandsLibraryLive => :strands,
    LantternWeb.StrandLive => :strands,
    LantternWeb.MomentLive => :strands,

    # students records
    LantternWeb.StudentsRecordsLive => :students_records,
    LantternWeb.StudentsRecordsSettingsLive => :students_records,

    # ILP
    LantternWeb.ILPLive => :ilp,
    LantternWeb.ILPSettingsLive => :ilp,

    # school
    LantternWeb.SchoolLive => :school_management,
    LantternWeb.ClassLive => :school_management,
    LantternWeb.StudentLive => :school_management,
    LantternWeb.StaffMemberLive => :school_management,
    LantternWeb.StudentsSettingsLive => :school_management,

    # assessment points
    LantternWeb.AssessmentPointsLive => :assessment_points,
    LantternWeb.AssessmentPointLive => :assessment_points,

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
    LantternWeb.GuardianHomeLive => :home,

    # student home
    LantternWeb.StudentHomeLive => :home,

    # student report cards
    LantternWeb.StudentReportCardsLive => :student_report_card,

    # student report card
    LantternWeb.StudentReportCardLive => :student_report_card,
    LantternWeb.StudentReportCardStrandReportLive => :student_report_card,

    # student strands
    LantternWeb.StudentStrandsLive => :student_strands,
    LantternWeb.StudentStrandReportLive => :student_strands,

    # student ILP
    LantternWeb.StudentILPLive => :student_ilp
  }

  def mount(socket) do
    active_nav = Map.get(@view_to_nav_map, socket.view)

    socket =
      socket
      |> assign(:locale_error, nil)
      |> assign(:active_nav, active_nav)
      |> stream(:school_cycles, [])
      |> assign(:school_cycles_loaded, false)
      |> assign(:has_school_cycles, false)
      |> stream(:profiles, [])
      |> assign(:profiles_loaded, false)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_nav_items()

    {:ok, socket}
  end

  defp assign_nav_items(socket) do
    all_nav_items = [
      # staff
      %{
        profile: "staff",
        active: :dashboard,
        path: ~p"/dashboard",
        text: gettext("Dashboard")
      },
      %{profile: "staff", active: :strands, path: ~p"/strands", text: gettext("Strands")},
      %{
        profile: "staff",
        active: :students_records,
        path: ~p"/students_records",
        text: gettext("Student records")
      },
      %{
        profile: "staff",
        active: :ilp,
        path: ~p"/ilp",
        text: gettext("ILP")
      },
      %{
        profile: "staff",
        active: :school_management,
        path: ~p"/school/classes",
        text: gettext("School management")
      },
      %{
        profile: "staff",
        active: :curriculum,
        path: ~p"/curriculum",
        text: gettext("Curriculum")
      },
      %{
        profile: "staff",
        active: :report_cards,
        path: ~p"/report_cards",
        text: gettext("Report cards")
      },
      %{
        profile: "staff",
        active: :grades_reports,
        path: ~p"/grades_reports",
        text: gettext("Grades reports")
      },
      # student
      %{
        profile: "student",
        active: :home,
        path: ~p"/student",
        text: gettext("Home")
      },
      %{
        profile: "student",
        active: :student_report_card,
        path: ~p"/student_report_cards",
        text: gettext("Report cards")
      },
      %{
        profile: "student",
        active: :student_strands,
        path: ~p"/student_strands",
        text: gettext("Strands")
      },
      %{
        profile: "student",
        active: :student_ilp,
        path: ~p"/student_ilp",
        text: gettext("My ILP")
      },
      # guardian
      %{
        profile: "guardian",
        active: :home,
        path: ~p"/guardian",
        text: gettext("Home")
      },
      %{
        profile: "guardian",
        active: :student_report_card,
        path: ~p"/student_report_cards",
        text: gettext("Report cards")
      },
      %{
        profile: "guardian",
        active: :student_strands,
        path: ~p"/student_strands",
        text: gettext("Strands")
      },
      %{
        profile: "guardian",
        active: :student_ilp,
        path: ~p"/student_ilp",
        text: gettext("ILP")
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

  def handle_event("stream_school_cycles", _, %{assigns: %{school_cycles_loaded: false}} = socket) do
    school_cycles =
      Schools.list_cycles(
        schools_ids: [socket.assigns.current_user.current_profile.school_id],
        parent_cycles_only: true
      )

    socket =
      socket
      |> stream(:school_cycles, school_cycles)
      |> assign(:school_cycles_loaded, true)
      |> assign(:has_school_cycles, length(school_cycles) > 0)

    {:noreply, socket}
  end

  def handle_event("stream_school_cycles", _, socket), do: {:noreply, socket}

  def handle_event("select_school_cycle", %{"id" => cycle_id}, socket) do
    socket =
      Personalization.set_profile_settings(
        socket.assigns.current_user.current_profile.id,
        %{current_school_cycle_id: cycle_id}
      )
      |> case do
        {:ok, _profile_setting} ->
          socket
          |> push_navigate(to: socket.assigns.current_path)
          |> put_flash(:info, gettext("Current cycle changed"))

        _ ->
          # do something with error
          socket
      end

    {:noreply, socket}
  end

  def handle_event("stream_user_profiles", _, %{assigns: %{profiles_loaded: false}} = socket) do
    profiles =
      Identity.list_profiles(
        user_id: socket.assigns.current_user.id,
        only_active: true,
        load_virtual_fields: true
      )

    socket =
      socket
      |> stream(:profiles, profiles)
      |> assign(:profiles_loaded, true)

    {:noreply, socket}
  end

  def handle_event("stream_user_profiles", _, socket), do: {:noreply, socket}

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
        "staff" -> ~p"/dashboard"
        "student" -> ~p"/student"
        "guardian" -> ~p"/guardian"
      end

    {:noreply, redirect(socket, to: to_path)}
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
