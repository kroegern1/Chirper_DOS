
# Supervisor code reference from:
# https://gist.github.com/andrewhao/c90f3d12cc92c0356f7d2d7173289071

defmodule Chirper.User.Supervisor do
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_user(username) do
    child_spec = {Chirper.User.Client, username}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def delete_user(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

   def children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def count_children do
    DynamicSupervisor.count_children(__MODULE__)
  end

end
