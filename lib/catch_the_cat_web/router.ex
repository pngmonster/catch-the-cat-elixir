defmodule CatchTheCatWeb.Router do
  use CatchTheCatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CatchTheCatWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CatchTheCatWeb do
    pipe_through :browser

    # Главная страница
    get "/", GameController, :index

    # API для ходов
    post "/move", GameController, :move
  end

  # Other scopes may use custom stacks.
  # scope "/api", CatchTheCatWeb do
  #   pipe_through :api
  # end
end
