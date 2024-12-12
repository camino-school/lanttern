defmodule LantternWeb.Router do
  use LantternWeb, :router

  import LantternWeb.UserAuth
  import LantternWeb.LocalizationHelpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LantternWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self' *.google.com *.googleapis.com plausible.io; style-src 'self' *.googleapis.com *.google.com 'unsafe-inline'; img-src * data: blob: 'self'; font-src *"
    }

    plug :fetch_current_user
    plug :put_locale
  end

  pipeline :admin do
    plug :put_layout, html: {LantternWeb.Layouts, :admin}
    plug :require_root_admin
  end

  # we skip the https://hexdocs.pm/sobelow/Sobelow.Config.CSRF.html
  # because for Sign In with Google pipeline we don't use :protect_from_forgery plug.
  # instead, we use :verify_google_csrf_token plug and
  # Lanttern.GoogleToken.verfify_and_validate/1

  pipeline :sign_in_with_google do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :verify_google_csrf_token
    plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'self'"}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # public routes
  scope "/", LantternWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # accept privacy policy route
  scope "/", LantternWeb do
    pipe_through [:browser, :require_authenticated_user, :redirect_if_privacy_policy_accepted]

    get "/accept_privacy_policy", PrivacyPolicyController, :accept_policy
    post "/accept_privacy_policy", PrivacyPolicyController, :save_accept_policy
  end

  # logged in and privacy policy accepted routes
  scope "/", LantternWeb do
    pipe_through [:browser, :require_authenticated_user, :require_privacy_policy_accepted]

    live_session :authenticated_teacher,
      layout: {LantternWeb.Layouts, :app_logged_in},
      on_mount: [
        {LantternWeb.UserAuth, :ensure_authenticated_teacher},
        {LantternWeb.Path, :put_path_in_socket}
      ] do
      live "/dashboard", DashboardLive, :index

      live "/school", SchoolLive, :show
      live "/school/students", SchoolLive, :manage_students
      live "/school/classes", SchoolLive, :manage_classes
      live "/school/cycles", SchoolLive, :manage_cycles

      live "/school/students/:id", StudentLive, :show
      live "/school/students/:id/report_cards", StudentLive, :report_cards
      live "/school/students/:id/grades_reports", StudentLive, :grades_reports

      live "/assessment_points/:id", AssessmentPointLive, :show
      live "/assessment_points/:id/edit", AssessmentPointLive, :edit
      live "/assessment_points/:id/rubrics", AssessmentPointLive, :rubrics

      live "/assessment_points/:id/student/:student_id/feedback",
           AssessmentPointLive,
           :feedback

      live "/strands", StrandsLive, :index
      live "/strands/library", StrandsLibraryLive, :index
      live "/strands/library/new", StrandsLibraryLive, :new

      live "/strands/:id", StrandLive, :show
      live "/strands/:id/rubrics", StrandLive, :rubrics
      live "/strands/:id/assessment", StrandLive, :assessment
      live "/strands/:id/moments", StrandLive, :moments
      live "/strands/:id/notes", StrandLive, :notes

      live "/strands/moment/:id", MomentLive, :show
      live "/strands/moment/:id/assessment", MomentLive, :assessment
      live "/strands/moment/:id/cards", MomentLive, :cards
      live "/strands/moment/:id/notes", MomentLive, :notes

      live "/rubrics", RubricsLive, :index
      live "/rubrics/new", RubricsLive, :new
      live "/rubrics/:id/edit", RubricsLive, :edit

      live "/curriculum", CurriculaLive, :index
      live "/curriculum/bncc_ef", BnccEfLive, :index
      live "/curriculum/:id", CurriculumLive, :show
      live "/curriculum/component/:id", CurriculumComponentLive, :show

      # report cards

      live "/report_cards", ReportCardsLive, :index
      live "/report_cards/new", ReportCardsLive, :new
      live "/report_cards/:id", ReportCardLive, :show
      live "/report_cards/:id/students", ReportCardLive, :students
      live "/report_cards/:id/strands", ReportCardLive, :strands
      live "/report_cards/:id/grades", ReportCardLive, :grades
      live "/report_cards/:id/tracking", ReportCardLive, :tracking

      # grading

      live "/grades_reports", GradesReportsLive
      live "/grades_reports/:id", GradesReportLive

      # students records

      live "/students_records", StudentsRecordsLive, :index
      live "/students_records/:id", StudentRecordLive, :show
    end

    live_session :authenticated_guardian,
      layout: {LantternWeb.Layouts, :app_logged_in},
      on_mount: [
        {LantternWeb.UserAuth, :ensure_authenticated_guardian},
        {LantternWeb.Path, :put_path_in_socket}
      ] do
      live "/guardian", GuardianHomeLive
    end

    live_session :authenticated_student,
      layout: {LantternWeb.Layouts, :app_logged_in},
      on_mount: [
        {LantternWeb.UserAuth, :ensure_authenticated_student},
        {LantternWeb.Path, :put_path_in_socket}
      ] do
      live "/student", StudentHomeLive

      # todo: move back to authenticated_student_or_guardian in the future
      live "/student_strands", StudentStrandsLive
    end

    live_session :authenticated_student_or_guardian,
      layout: {LantternWeb.Layouts, :app_logged_in},
      on_mount: [
        {LantternWeb.UserAuth, :ensure_authenticated_student_or_guardian},
        {LantternWeb.Path, :put_path_in_socket}
      ] do
      live "/strand_report/:strand_report_id",
           StudentStrandReportLive,
           :show
    end

    live_session :authenticated_user,
      layout: {LantternWeb.Layouts, :app_logged_in},
      on_mount: [
        {LantternWeb.UserAuth, :ensure_authenticated},
        {LantternWeb.Path, :put_path_in_socket}
      ] do
      live "/student_report_card/:id", StudentReportCardLive, :show

      live "/student_report_card/:student_report_card_id/strand_report/:strand_report_id",
           StudentReportCardStrandReportLive,
           :show
    end
  end

  scope "/admin", LantternWeb do
    pipe_through [:browser, :require_authenticated_user, :admin]

    get "/", AdminController, :home
    post "/seed_base_taxonomy", AdminController, :seed_base_taxonomy
    post "/seed_bncc", AdminController, :seed_bncc

    # Identity context
    resources "/users", UserController
    resources "/profiles", ProfileController

    live "/profile_settings", Admin.ProfileSettingsLive.Index, :index
    live "/profile_settings/:profile_id/edit", Admin.ProfileSettingsLive.Index, :edit

    # Assessments context
    resources "/assessment_points", AssessmentPointController
    resources "/assessment_point_entries", AssessmentPointEntryController
    resources "/feedback", FeedbackController

    # Curricula context
    resources "/curricula", CurriculumController
    resources "/curriculum_components", CurriculumComponentController
    resources "/curriculum_items", CurriculumItemController
    resources "/curriculum_relationships", CurriculumRelationshipController

    # Grading context
    resources "/ordinal_values", OrdinalValueController
    resources "/scales", ScaleController

    # Schools context
    resources "/schools", SchoolController
    resources "/classes", ClassController
    resources "/students", StudentController
    resources "/teachers", TeacherController

    live "/import_students", Admin.ImportStudentsLive
    live "/import_teachers", Admin.ImportTeachersLive

    live "/school_cycles", Admin.CycleLive.Index, :index
    live "/school_cycles/new", Admin.CycleLive.Index, :new

    live "/school_cycles/:id/edit", Admin.CycleLive.Index, :edit
    live "/school_cycles/:id", Admin.CycleLive.Show, :show
    live "/school_cycles/:id/show/edit", Admin.CycleLive.Show, :edit

    # Taxonomy context
    resources "/subjects", SubjectController
    resources "/years", YearController

    # Conversation context
    resources "/comments", CommentController

    # Rubrics context
    live "/rubrics", Admin.RubricLive.Index, :index
    live "/rubrics/new", Admin.RubricLive.Index, :new
    live "/rubrics/:id/edit", Admin.RubricLive.Index, :edit

    live "/rubrics/:id", Admin.RubricLive.Show, :show
    live "/rubrics/:id/show/edit", Admin.RubricLive.Show, :edit

    # Learning Context context
    live "/strands", Admin.StrandLive.Index, :index
    live "/strands/new", Admin.StrandLive.Index, :new
    live "/strands/:id/edit", Admin.StrandLive.Index, :edit

    live "/strands/:id", Admin.StrandLive.Show, :show
    live "/strands/:id/show/edit", Admin.StrandLive.Show, :edit

    live "/moments", Admin.MomentLive.Index, :index
    live "/moments/new", Admin.MomentLive.Index, :new
    live "/moments/:id/edit", Admin.MomentLive.Index, :edit

    live "/moments/:id", Admin.MomentLive.Show, :show
    live "/moments/:id/show/edit", Admin.MomentLive.Show, :edit

    live "/moment_cards", Admin.MomentCardLive.Index, :index
    live "/moment_cards/new", Admin.MomentCardLive.Index, :new
    live "/moment_cards/:id/edit", Admin.MomentCardLive.Index, :edit

    live "/moment_cards/:id", Admin.MomentCardLive.Show, :show
    live "/moment_cards/:id/show/edit", Admin.MomentCardLive.Show, :edit

    # Personalization context
    live "/notes", Admin.NoteLive.Index, :index
    live "/notes/new", Admin.NoteLive.Index, :new
    live "/notes/:id/edit", Admin.NoteLive.Index, :edit

    live "/notes/:id", Admin.NoteLive.Show, :show
    live "/notes/:id/show/edit", Admin.NoteLive.Show, :edit

    # Reporting context
    live "/report_cards", Admin.ReportCardLive.Index, :index
    live "/report_cards/new", Admin.ReportCardLive.Index, :new
    live "/report_cards/:id/edit", Admin.ReportCardLive.Index, :edit

    live "/report_cards/:id", Admin.ReportCardLive.Show, :show
    live "/report_cards/:id/show/edit", Admin.ReportCardLive.Show, :edit

    live "/strand_reports", Admin.StrandReportLive.Index, :index
    live "/strand_reports/new", Admin.StrandReportLive.Index, :new
    live "/strand_reports/:id/edit", Admin.StrandReportLive.Index, :edit

    live "/strand_reports/:id", Admin.StrandReportLive.Show, :show
    live "/strand_reports/:id/show/edit", Admin.StrandReportLive.Show, :edit

    live "/student_report_cards", Admin.StudentReportCardLive.Index, :index
    live "/student_report_cards/new", Admin.StudentReportCardLive.Index, :new
    live "/student_report_cards/:id/edit", Admin.StudentReportCardLive.Index, :edit

    live "/student_report_cards/:id", Admin.StudentReportCardLive.Show, :show
    live "/student_report_cards/:id/show/edit", Admin.StudentReportCardLive.Show, :edit

    # Students records

    live "/students_records", Admin.StudentRecordLive.Index, :index
    live "/students_records/new", Admin.StudentRecordLive.Index, :new
    live "/students_records/:id/edit", Admin.StudentRecordLive.Index, :edit

    live "/students_records/:id", Admin.StudentRecordLive.Show, :show
    live "/students_records/:id/show/edit", Admin.StudentRecordLive.Show, :edit

    live "/student_record_types", Admin.StudentRecordTypeLive.Index, :index
    live "/student_record_types/new", Admin.StudentRecordTypeLive.Index, :new
    live "/student_record_types/:id/edit", Admin.StudentRecordTypeLive.Index, :edit

    live "/student_record_types/:id", Admin.StudentRecordTypeLive.Show, :show
    live "/student_record_types/:id/show/edit", Admin.StudentRecordTypeLive.Show, :edit

    live "/student_record_statuses", Admin.StudentRecordStatusLive.Index, :index
    live "/student_record_statuses/new", Admin.StudentRecordStatusLive.Index, :new
    live "/student_record_statuses/:id/edit", Admin.StudentRecordStatusLive.Index, :edit

    live "/student_record_statuses/:id", Admin.StudentRecordStatusLive.Show, :show
    live "/student_record_statuses/:id/show/edit", Admin.StudentRecordStatusLive.Show, :edit
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
      # live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      # live "/users/reset_password", UserForgotPasswordLive, :new
      # live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", LantternWeb do
    pipe_through :sign_in_with_google

    post "/users/google_sign_in", UserSessionController, :google_sign_in
  end

  # scope "/", LantternWeb do
  #   pipe_through [:browser, :require_authenticated_user]

  #   live_session :require_authenticated_user,
  #     on_mount: [{LantternWeb.UserAuth, :ensure_authenticated}] do
  #     live "/users/settings", UserSettingsLive, :edit
  #     live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
  #   end
  # end

  scope "/", LantternWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    # live_session :current_user,
    #   on_mount: [{LantternWeb.UserAuth, :mount_current_user}] do
    #   live "/users/confirm/:token", UserConfirmationLive, :edit
    #   live "/users/confirm", UserConfirmationInstructionsLive, :new
    # end
  end
end
