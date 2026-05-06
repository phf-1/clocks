defmodule BackendWeb.Router do
  @moduledoc """
  [[id:30bce120-ef3c-45df-a736-efaf76bddbfe][Id]] implements [[ref:9dff3c23-619d-45e5-be70-a00410129737][protocol]].
  """

  use BackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug BackendWeb.Plugs.RequireAuth
  end

  scope "/api", BackendWeb do
    pipe_through :api

    options "/*path", AuthController, :options
    get "/health", HealthController, :health
    post "/auth/signup", AuthController, :signup
    post "/auth/signin", AuthController, :signin

    pipe_through :authenticated

    post "/auth/signout", AuthController, :signout
    get "/auth/me", AuthController, :me
    get "/todos", TodoController, :index
    post "/todos", TodoController, :create
    patch "/todos/:todo_id", TodoController, :update
    delete "/todos/:todo_id", TodoController, :delete
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BackendWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", BackendWeb do
    pipe_through :browser
    get "/", Controller, :spa
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:backend, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BackendWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
