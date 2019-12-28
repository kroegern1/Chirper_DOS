defmodule ChirperWeb.UserController do
  use ChirperWeb, :controller

  def index(conn, params) do
    username = params["uname"]
    pid = GenServer.call(Chirper.Engine.Manager, {:register_account, username})
    dash = GenServer.call(pid, :get_dash)
    IO.inspect(dash)
    render(conn, "user.html", user: username, dash: dash)
  end



end
