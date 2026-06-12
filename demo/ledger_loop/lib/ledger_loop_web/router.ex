defmodule LedgerLoopWeb.Router do
  use LedgerLoopWeb, :router

  import Relyra.LiveAdmin.Router
  import Relyra.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LedgerLoopWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :health do
    plug(:accepts, ["json"])
  end

  scope "/" do
    pipe_through(:health)

    get("/healthz", LedgerLoopWeb.HealthController, :health)
    get("/readyz", LedgerLoopWeb.HealthController, :ready)
  end

  scope "/" do
    pipe_through :browser

    get "/", LedgerLoopWeb.PageController, :home
    live "/setup/sso", LedgerLoopWeb.SetupLive, :index
    get "/login/test", LedgerLoopWeb.RouteAffordanceController, :login
    get "/login/admin", LedgerLoopWeb.RouteAffordanceController, :admin_login
    get "/support/scenario", LedgerLoopWeb.RouteAffordanceController, :support

    relyra_admin_routes("/relyra/admin",
      repo: LedgerLoop.Repo,
      scope_provider: LedgerLoop.Relyra.AdminScope
    )
  end

  scope "/saml" do
    pipe_through :browser

    saml_routes()
  end

  # Other scopes may use custom stacks.
  # scope "/api", LedgerLoopWeb do
  #   pipe_through :api
  # end
end
