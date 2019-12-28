defmodule Chirper.Engine.Server do
  # This process handle external messages to the server engine
  # It interfaces with the ETS storage, delegates tasks to the manager
  # When the client initiates sending a tweet, the server handles it
  # It distributes those messages to the proper clients
  # It pings clients with mentions
  # It processes retweets

  use GenServer

  # Client API
  def start_link(map \\ %{}) do
    GenServer.start_link(__MODULE__, map, name: __MODULE__)
  end

  # Callbacks
  def init(state \\ %{}) do
    # init ETS tables
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
    {_, _, ts, _, hastags, mentions, _} = tweet

    Enum.each(follower_list, fn user ->
      # server sends tuple "key" to each client that follows the sender
      GenServer.cast(state[user], {:receive_tweet, {sender, ts}})
    end)

    peopleLeftToContact = mentions -- follower_list

    Enum.each(peopleLeftToContact, fn user ->
      # server sends tuple "key" to each mentionee
      GenServer.cast(state[user], {:receive_tweet, {sender, ts}})
    end)

    Enum.each(hastags, fn tag ->
      :ets.insert(:hashtags, {tag, sender, ts})
    end)

    {:reply, :ok, state}
  end

  # handle query (hashtags)
  def handle_call({:query, hashtag}, _from, state) do
    results =
      :ets.lookup(:hashtags, hashtag)
      |> Enum.map(fn {_, author, ts} ->
        :ets.match_object(:tweets, {author, :_, ts, :_, :_, :_, :_})
      end)
      |> List.flatten()

    {:reply, results, state}
  end

  def handle_call({:user_exists?, username}, _from, state) do
    case state[username] do
      nil -> {:reply, false, state}
      pid -> {:reply, pid, state}
    end
  end

  def handle_call({:remove_user, username}, _from, state) do
    case state[username] do
      nil ->
        {:reply, false, state}

      pid ->
        Map.delete(state, username)
        {:reply, pid, state}
    end
  end

  def handle_call({:get_user_tweets, user}, _from, state) do
    case state[user] do
      nil ->
        {:reply, [], state}

      pid ->
        reply = :ets.match_object(:tweets, {user, :_, :_, :_, :_, :_, :_})
        {:reply, reply, state}
    end
  end

  def handle_call({:get_num_following, user}, _from, state) do
    case state[user] do
      nil ->
        {:reply, 0, state}

      pid ->
        reply = :ets.match_object(:following, {user, :_})
        reply = Kernel.length(reply)
        {:reply, reply, state}
    end
  end

  def handle_call({:get_num_followers, user}, _from, state) do
    case state[user] do
      nil ->
        {:reply, 0, state}

      pid ->
        reply = :ets.match_object(:followers, {user, :_})
        reply = Kernel.length(reply)
        {:reply, reply, state}
    end
  end

  def handle_call({:get_num_mentions, user}, _from, state) do
    case state[user] do
      nil ->
        {:reply, 0, state}

      pid ->
        dash = GenServer.call(state[user], :get_dash)
        numMentions = getNumberOfMentions(dash, user)
        {:reply, numMentions, state}
    end
  end

  defp getNumberOfMentions(dash, user) do
    user = String.slice(user, 1..-1)
    numMentions = Enum.map(dash, fn d ->
      {_, _, _, _, _, mentionList, _} = d
      tempNum = if Enum.member?(mentionList, user) do
        1
      else
        0
      end
      tempNum
    end)
    Enum.sum(numMentions)
  end

  # handle follow
  def handle_cast({:follow, requester, to_follow}, state) do
    :ets.insert(:following, {requester, to_follow})
    :ets.insert(:followers, {to_follow, requester})
    {:noreply, state}
  end
end
