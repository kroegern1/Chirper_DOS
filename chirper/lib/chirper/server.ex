defmodule Chirper.Server do
  # This process handle external messages to the server engine
  # It interfaces with the ETS storage, delegates tasks to the manager
  # When the client initiates sending a tweet, the server handles it
  # It distributes those messages to the proper clients
  # It pings clients with mentions
  # It processes retweets

  use GenServer

  def init(state \\ %{}) do
    :ets.new(:tweets, [:bag, :protected, :named_table, read_concurrency: true])
    :ets.new(:following, [:bag, :protected, :named_table, read_concurrency: true])
    :ets.new(:followers, [:bag, :protected, :named_table, read_concurrency: true])
    :ets.new(:hashtags, [:bag, :protected, :named_table, read_concurrency: true])

    {:ok, state}
  end

  # handle registration
  def handle_call({:add_account, username, pid}, _from, state) do
    {:reply, :ok, Map.put(state, username, pid)}
  end

  # handle and distribute tweet
  def handle_call({:send_tweet, tweet, sender}, _from, state) do
    :ets.insert(:tweets, tweet)
    follower_list = :ets.match(:followers, {sender, :"$1"}) |> List.flatten()
    {_, _, ts, _, hashtags, mentions, _} = tweet

    Enum.each(hashtags, fn tag ->
      :ets.insert(:hashtags, {tag, sender, ts})
    end)

    Enum.each(follower_list, fn user ->
      # server sends tuple "key" to each client that follows the sender
      GenServer.cast(state[user], {:receive_tweet, {sender, ts}})
    end)

    Enum.each(mentions, fn user ->
      # server sends tuple "key" to each mentionee
      GenServer.cast(state[user], {:receive_tweet, {sender, ts}})
    end)

    {:reply, :ok, state}
  end

  # handle query (hashtags)
  def handle_call({:query, hashtag}, _from, state) do
    #todo
      {:reply, hashtag, state}
  end

  # handle follow
  def handle_cast({:follow, requester, to_follow}, state) do
    :ets.insert(:following, {requester, to_follow})
    :ets.insert(:followers, {to_follow, requester})
    {:noreply, state}
  end

end
