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

  # SAML endpoints need browser-style session handling, but the ACS receives an
  # IdP-originated POST that cannot carry our CSRF token. SkipCSRF runs BEFORE
  # protect_from_forgery so the ACS route's `relyra_skip_csrf` private flag (set
  # by saml_routes/0) exempts it, while the form-login POST keeps CSRF. Piping
  # saml_routes through :browser instead lets protect_from_forgery raise first,
  # which 403s the self-submitting SAMLResponse before it reaches the verifier.
  pipeline :saml do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LedgerLoopWeb.Layouts, :root}
    plug Relyra.Phoenix.Pipeline.SkipCSRF
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :health do
    plug(:accepts, ["json"])
  end

  pipeline :demo_admin do
    plug LedgerLoopWeb.Plugs.DemoAdminAuth
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
    get "/support/scenario", LedgerLoopWeb.RouteAffordanceController, :support

    get "/fake_idp/login", LedgerLoopWeb.FakeIdPController, :login
    post "/fake_idp/sso", LedgerLoopWeb.FakeIdPController, :sso
  end

  scope "/" do
    pipe_through [:browser, :demo_admin]

    get "/login/admin", LedgerLoopWeb.RouteAffordanceController, :admin_login

    relyra_admin_routes("/relyra/admin",
      repo: LedgerLoop.Repo,
      scope_provider: LedgerLoop.Relyra.AdminScope
    )
  end

  scope "/saml" do
    pipe_through :saml

    saml_routes()
  end

  # Other scopes may use custom stacks.
  # scope "/api", LedgerLoopWeb do
  #   pipe_through :api
  # end
end
