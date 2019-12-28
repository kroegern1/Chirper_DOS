defmodule ChirperWeb.Router do
  use ChirperWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ChirperWeb do
    pipe_through :browser
    #resources "/users", UserController
    get "/", PageController, :index
    get "/user/:username", UserController, :index
    get "/user", UserController, :index

    get "/userSearch/:username", UserSearchController, :index
    get "/userSearch", UserSearchController, :index

    get "/hashtagSearch/:hashtag", HashtagsController, :index
    get "/hashtagSearch", HashtagsController, :index

  end

  # Other scopes may use custom stacks.
  # scope "/api", ChirperWeb do
  #   pipe_through :api
  # end
end
