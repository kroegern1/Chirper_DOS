defmodule Chirper.Engine.Manager do
  # This process handles users, user registration and process generation for the server

  use GenServer

  # request and generate account
  # spawn new process
  # get pid
  # get username
  # send it to server and add it to its state

  # Client API
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def register(username) do
    GenServer.call(__MODULE__, {:register_account, username})
  end

  def delete(username) do
    GenServer.call(__MODULE__, {:delete_account, username})
  end

  # Server
  def init(state \\ []) do
    Chirper.User.Supervisor.start_link([])
    {:ok, state}
  end

  def handle_call({:register_account, username}, _from, state) do
    # query server for username to see if it exists
    case GenServer.call(Chirper.Engine.Server, {:user_exists?, username}) do
      false ->
        {:ok, pid} = Chirper.User.Supervisor.add_user(username)
        GenServer.call(Chirper.Engine.Server, {:add_account, username, pid})
        {:reply, pid, state}

      pid ->
        {:reply, pid, state}
    end
  end

  def handle_call({:delete_account, username}, _from, state) do
    case GenServer.call(Chirper.Engine.Server, {:remove_user, username}) do
      false ->
        {:reply, :error, state}

      pid ->
        Chirper.User.Supervisor.delete_user(pid)
        {:reply, :ok, state}
    end
  end
end
