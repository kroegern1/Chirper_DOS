defmodule Chirper.User.Client do

  # This is the server side client process for a given user
  # it maintains a state that contains the list of tweets that comprise a user's timeline

  use GenServer
  def start_link(username) do
    GenServer.start_link(__MODULE__, username)
  end

  def init(user) do
    {:ok, {{user, 0}, []}}
  end

  #send tweet
  def handle_call({:send_tweet, body}, _from, {{this_user, counter},dash}) do
    #{:ok, ts} = DateTime.now("Etc/UTC")
    ts = :os.system_time(:millisecond) + counter
    #IO.puts("current time: #{ts}")
    tweet = parse_tweet(this_user,ts,body)
    GenServer.call(Chirper.Engine.Server, {:send_tweet, tweet, this_user})
    {:reply, {:ok,tweet}, {{this_user, counter + 1},dash}}
  end

  #get dashboard
  def handle_call(:get_dash, _from, {user_stats, dash}) do
    results = Enum.map(dash, fn {this_user, ts} ->
      [query] = :ets.match_object(:tweets, {this_user, :"$1", ts, :"$2", :_, :_, :"$3"})
      query
    end)
    {:reply, results, {user_stats, dash}}
  end

  #query server
  def handle_call({:search_hashtag, hashtag}, _from, {user_stats, dash}) do
    keys = :ets.match(:hashtags, hashtag)
    results = Enum.map(keys, fn {this_user, ts} ->
      [query] = :ets.match_object(:tweets, {this_user, :"$1", ts, :"$2", :_, :_, :"$3"})
      query
    end)
    {:reply, results, {user_stats, dash}}
  end

  #retweet
  def handle_call({:retweet, {user, ts}}, _from, {{this_user, counter},dash}) do
    #{:ok, new_ts} = DateTime.now("Etc/UTC")
    new_ts = :os.system_time(:millisecond) + counter
    [{_poster, op, _timestamp, body, hashtags, mentions, _retweeted}] = :ets.match_object(:tweets, {user, :"$1", ts, :"$2", :_, :_, :"$3"})
    tweet = {this_user, op, new_ts, body, hashtags, mentions, :true}
    GenServer.call(Chirper.Engine.Server, {:send_tweet, tweet, this_user})
    {:reply, {:ok,tweet}, {{this_user, counter + 1},dash}}
  end

  #receive tweet
  def handle_cast({:receive_tweet, key}, {{this_user, counter},dash}) do
    {:noreply, {{this_user, counter},dash ++ [key]}}
  end

  #follow user
  def handle_cast({:follow, user_to_follow}, {{this_user, counter},dash}) do
    GenServer.cast(Chirper.Engine.Server, {:follow, this_user, user_to_follow })
    {:noreply, {{this_user, counter},dash}}
  end



  ## Helper Function
  def parse_tweet(this_user, ts, body) do
    hashtags = Regex.scan(~r/#[[:alnum:]]+/, body) |> List.flatten
    mentions = Regex.scan(~r/@[[:alnum:]]+/, body) |> List.flatten
    mentions = Enum.map(mentions, fn x ->
      String.slice(x, 1..-1)
    end)

    hashtags = Enum.map(hashtags, fn x ->
     String.slice(x, 1..-1)
    end)

    {this_user, this_user, ts, body, hashtags, mentions, :false}

  end

end

