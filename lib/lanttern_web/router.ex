defmodule LantternWeb.Router do
  use LantternWeb, :router

  import LantternWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LantternWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :admin do
    plug :put_layout, html: {LantternWeb.Layouts, :admin}
    plug :require_root_admin
  end

  pipeline :sign_in_with_google do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :verify_google_csrf_token
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LantternWeb do
    pipe_through :browser

    get "/", PageController, :home

    live_session :authenticated, on_mount: {LantternWeb.UserAuth, :ensure_authenticated} do
      live "/dashboard", DashboardLive

      live "/assessment_points", AssessmentPointsLive
      live "/assessment_points/explorer", AssessmentPointsExplorerLive
      live "/assessment_points/:id", AssessmentPointLive

      live "/curriculum", CurriculumLive
      live "/curriculum/bncc_ef", CurriculumBNCCEFLive
    end
  end

  scope "/admin", LantternWeb do
    pipe_through [:browser, :require_authenticated_user, :admin]

    get "/", AdminController, :home

    scope "/assessments" do
      resources "/assessment_points", AssessmentPointController
      resources "/assessment_point_entries", AssessmentPointEntryController
    end

    scope "/curricula" do
      resources "/cur", CurriculumController
      resources "/curriculum_components", CurriculumComponentController
      resources "/curriculum_items", CurriculumItemController
      resources "/curriculum_relationships", CurriculumRelationshipController
    end

    scope "/grading" do
      resources "/compositions", CompositionController
      resources "/composition_components", CompositionComponentController
      resources "/component_items", CompositionComponentItemController
      resources "/ordinal_values", OrdinalValueController
      resources "/scales", ScaleController
    end

    scope "/schools" do
      resources "/schools", SchoolController
      resources "/classes", ClassController
      resources "/students", StudentController
      resources "/teachers", TeacherController
    end

    scope "/taxonomy" do
      resources "/subjects", SubjectController
      resources "/years", YearController
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", LantternWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:lanttern, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LantternWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", LantternWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{LantternWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", LantternWeb do
    pipe_through :sign_in_with_google

    post "/users/google_sign_in", UserSessionController, :google_sign_in
  end

  scope "/", LantternWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{LantternWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", LantternWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{LantternWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
