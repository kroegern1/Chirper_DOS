defmodule Chirper.Simulator.Actor do

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init({username, follow_list, tweet_list}) do
    #register account
    follow_list = if is_binary(follow_list) do #1 item (it's a string, convert to list)
      List.wrap(follow_list)
    else
      List.flatten(follow_list)
    end

    #IO.inspect(follow_list)
    client = GenServer.call(Chirper.Engine.Manager, {:register_account, username})
    {:ok, {username, client, {follow_list, tweet_list}}}
  end

  def handle_call(:do_follow, _from, {username, client, {follow_list, tweet_list}}) do
    #follow users in user list
    Enum.each(follow_list, fn userToFollow ->
      GenServer.cast(client, {:follow, userToFollow})
    end)
    {:reply, :ok, {username, client, {follow_list, tweet_list}}}
  end

  def handle_call(:do_tweets, _from, {username, client, {follow_list, tweet_list}}) do
     # send tweets
     Enum.map(tweet_list, fn t ->
      {:ok, _tweet} = GenServer.call(client, {:send_tweet, t})
      #Process.sleep(1)
    end)
    {:reply, :ok, {username, client, {follow_list, tweet_list}}}
  end

  def handle_call(:do_retweets, _from, {username, client, {follow_list, tweet_list}}) do
    case GenServer.call(client, :get_dash) do
      [] ->
        {:reply, :error, {username, client, {follow_list, tweet_list}}}

      dash ->
        {author, _, ts, _, _, _, _} = Enum.random(dash)
        {:ok, _tweet} = GenServer.call(client, {:retweet, {author, ts}})
        {:reply, :ok, {username, client, {follow_list, tweet_list}}}
    end
  end

  #get dashboard
  # GenServer.call(Enum.at(pids,0), {:get_dash})
  def handle_call(:get_dash_actor, _from, {username, client, {follow_list, tweet_list}}) do
    dash = GenServer.call(client, :get_dash)
    #require IEx; IEx.pry
    {:reply, dash, {username, client, {follow_list, tweet_list}}}
  end

  def handle_call(:report,_from, {username, client, {follow_list, tweet_list}}) do
    #Get number of mentions
    dash = GenServer.call(client, :get_dash)
    numMentions = getNumberOfMentions(dash)

    IO.puts("User: #{username}\n...Followed #{Kernel.length(follow_list)} users\n...Sent\t    #{Kernel.length(tweet_list)} tweets\n...Received #{numMentions} mentions\n...Saw\t    #{Kernel.length(dash)} tweets")
    IO.puts("")
    {:reply,:ok, {username, client, {follow_list, tweet_list}}}
  end

  defp getNumberOfMentions(dash) do
    numMentions = Enum.map(dash, fn d ->
      {_, _, _, _, _, mentionList, _} = d
      Kernel.length(mentionList)
    end)
    Enum.sum(numMentions)
  end


  # report results:
  #   followed x people
  #   sent x tweets
  #   received x mentions
  #   saw x tweets on dashboard

end
