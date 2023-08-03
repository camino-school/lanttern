defmodule LantternWeb.Router do
  use LantternWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LantternWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LantternWeb do
    pipe_through :browser

    get "/", PageController, :home

    scope "/assessments" do
      resources "/assessment_points", AssessmentPointController
      resources "/assessment_point_entries", AssessmentPointEntryController
    end

    scope "/curricula" do
      resources "/items", ItemController
    end

    scope "/grading" do
      resources "/compositions", CompositionController
      resources "/composition_components", CompositionComponentController
      resources "/component_items", CompositionComponentItemController
      resources "/ordinal_values", OrdinalValueController
      resources "/scales", ScaleController
    end

    scope "/schools" do
      resources "/students", StudentController
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
end
