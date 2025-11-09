defmodule GroupDealsWeb.Router do
  use GroupDealsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GroupDealsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GroupDealsWeb do
    pipe_through :browser

    live "/gap/pages_groups", PagesGroupLive.Index, :index
    live "/gap/pages_groups/new", PagesGroupLive.Form, :new
    live "/gap/pages_groups/:id", PagesGroupLive.Show, :show
    live "/gap/pages_groups/:id/edit", PagesGroupLive.Form, :edit

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", GroupDealsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:group_deals, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GroupDealsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
