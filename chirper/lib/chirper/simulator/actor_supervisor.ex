
# Supervisor code reference from:
# https://gist.github.com/andrewhao/c90f3d12cc92c0356f7d2d7173289071

defmodule Chirper.Simulator.Supervisor do
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def spawn_actor(username, follow_list, tweet_list) do
    child_spec = %{
      :id => username,
      :start => {Chirper.Simulator.Actor, :start_link, [{username, follow_list, tweet_list}]},
      :restart => :temporary
    }
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

   def children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def count_children do
    DynamicSupervisor.count_children(__MODULE__)
  end

end
