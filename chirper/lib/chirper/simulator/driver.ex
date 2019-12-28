defmodule Chirper.Simulator.Driver do
  # example: pids = Chirper.Simulator.Driver.run([3,2])
  # example: pids = Chirper.Simulator.Driver.runWithZipf([10, 9])
  # GenServer.call(Enum.at(pids,0), :get_dash_actor)

  use GenServer
  # Client API
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def run([num_user, num_tweets]) do
    IO.puts("Running simulation with #{num_user} users sending #{num_tweets} tweets")
    Simulator.Helper.load_tweet_collection()

    # Generate list of usernames
    usernames = Simulator.Helper.getUsernames(num_user)

    # each person follows
    followingList = Simulator.Helper.getFollowingList(usernames)

    # "Each user must make num_tweets"
    tweetList = Simulator.Helper.getTweetList(usernames, num_tweets)

    start_time = System.os_time(:millisecond)

    # Spawn users
    pids = spawn_users(usernames, followingList, tweetList)
    # flatten list
    pids = List.flatten(pids)
    # remove last element
    pids = pids |> Enum.reverse() |> tl() |> Enum.reverse()
    # IO.inspect(pids)

    Enum.each(pids, fn pid ->
      GenServer.call(pid, :do_follow)
    end)

    Enum.each(pids, fn pid ->
      GenServer.call(pid, :do_tweets)
    end)

    Enum.each(pids, fn pid ->
      GenServer.call(pid, :report)
    end)

    end_time = System.os_time(:millisecond)
    IO.puts("Simulation completed in #{(end_time - start_time) / 1000} seconds.")
    pids
  end

  def runWithZipf([num_user, peak_frequency]) do
    #     Simulate a Zipf distribution on the number of subscribers. For accounts with a lot
    # of subscribers, increase the number of tweets. Make some of these messages’ re-tweets.
    #   Requirement: peak_frequency < num_user. (e.g. num_user = 100, peak_frequency = 99)
    #     peak_frequency is the most amount of followers someone can have

    IO.puts(
      "Running Zipf simulation with #{num_user} users and peak_frequency: #{peak_frequency}."
    )

    Simulator.Helper.load_tweet_collection()

    # Generate list of usernames
    usernames = Simulator.Helper.getUsernames(num_user)

    # each person follows
    {followingList, zipf} =
      Simulator.Helper.getFollowingListZipf(usernames, num_user, peak_frequency)

    IO.inspect(zipf)

    # "Each user must make num_tweets"
    tweetList = Simulator.Helper.getTweetListZipf(usernames, zipf)

    start_time = System.os_time(:millisecond)

    # Spawn users
    pids = spawn_usersZipf(usernames, followingList, tweetList)
    # flatten list
    pids = List.flatten(pids)
    # remove last element
    pids = pids |> Enum.reverse() |> tl() |> Enum.reverse()
    # IO.inspect(pids)

    # follow users in following list
    Enum.each(pids, fn pid ->
      GenServer.call(pid, :do_follow)
    end)

    # send all tweets in tweet list
    Enum.each(pids, fn pid ->
      GenServer.call(pid, :do_tweets)
    end)

    # retweet one tweet from dashboard/mentions
    Enum.each(pids, fn pid ->
      GenServer.call(pid, :do_retweets)
    end)

    # report results
    Enum.each(pids, fn pid ->
      GenServer.call(pid, :report)
    end)

    end_time = System.os_time(:millisecond)
    IO.puts("Simulation completed in #{(end_time - start_time) / 1000} seconds.")
    pids
  end

  # Server
  def init(state \\ []) do
    Chirper.Simulator.Supervisor.start_link([])
    {:ok, state, {:continue, :run}}
  end

  def handle_continue(:run, state) do
    runWithZipf([100, 99])
    {:noreply, state}
  end

  def spawn_usersZipf([username | usernames], [following | followings], [tweet | tweets]) do
    IO.puts("Spawning user #{username}")
    # IO.inspect(following)
    {:ok, pid} = spawn_user(username, following, tweet)
    # recursively store pids
    [pid] ++ [spawn_users(usernames, followings, tweets)]
  end

  def spawn_users([username | usernames], [following | followings], [tweet | tweets]) do
    IO.puts("Spawning user #{username}")
    # IO.inspect(following)
    {:ok, pid} = spawn_user(username, [following], tweet)
    # recursively store pids
    [pid] ++ [spawn_users(usernames, followings, tweets)]
  end

  def spawn_users(_, [], []) do
    nil
  end

  def spawn_user(username, follow_list, tweet_list) do
    Chirper.Simulator.Supervisor.spawn_actor(username, follow_list, tweet_list)
  end
end

defmodule Simulator.Helper do
  def load_tweet_collection do
    :ets.new(:tweetComponents, [:bag, :protected, :named_table, read_concurrency: true])

    contents = File.read("lib/chirper/simulator/tweet_parts.txt")
    {:ok, contents} = contents

    {myOS, _} = :os.type()

    splitChar =
      if myOS == :win32 do
        # \r for windows machines
        "\r\n"
      else
        "\n"
      end

    contents
    |> String.split(splitChar)
    |> Enum.each(fn x ->
      [key, value] = String.split(x, "=")
      :ets.insert(:tweetComponents, {key, value})
    end)
  end

  def make_tweet(usernameList) do
    randomUsername1 = Enum.random(usernameList)

    randomUsername2 =
      if Kernel.length(usernameList) > 1 do
        # don't select same person twice
        tempUserList = List.delete(usernameList, randomUsername1)
        Enum.random(tempUserList)
      else
        ""
      end

    [body] = :ets.match(:tweetComponents, {"body", :"$1"}) |> Enum.random()
    [tag1] = :ets.match(:tweetComponents, {"tag", :"$1"}) |> Enum.random()
    [tag2] = :ets.match(:tweetComponents, {"tag", :"$1"}) |> Enum.random()

    t1 = randomUsername1 <> body <> tag1
    t2 = randomUsername1 <> body <> tag1 <> tag2
    t3 = randomUsername1 <> " " <> randomUsername2 <> body <> tag1
    t4 = randomUsername1 <> " " <> randomUsername2 <> body <> tag1 <> tag2
    t5 = body

    randomlyPickedTweet =
      if Kernel.length(usernameList) > 1 do
        [t1, t2, t3, t4, t5] |> Enum.random()
      else
        [t1, t2, t5] |> Enum.random()
      end

    randomlyPickedTweet
  end

  def getUsernames(num_user) do
    # Create list 1 to num_user
    userList = Enum.to_list(1..num_user)
    allUsersStoredInTextFile = :ets.match(:tweetComponents, {"name", :"$1"})
    totalPredefinedUsers = Kernel.length(allUsersStoredInTextFile)

    Enum.map(userList, fn u ->
      cond do
        u >= totalPredefinedUsers ->
          newU = rem(u, totalPredefinedUsers)

          tempName =
            :ets.match(:tweetComponents, {"name", :"$1"})
            |> Enum.at(newU)
            |> Enum.at(0)
            |> String.slice(1..-1)

          tempName <> Integer.to_string(u)

        true ->
          :ets.match(:tweetComponents, {"name", :"$1"})
          |> Enum.at(u)
          |> Enum.at(0)
          |> String.slice(1..-1)
      end
    end)
  end

  def getFollowingList(usernames) do
    Enum.map(usernames, fn u ->
      tempUserList = List.delete(usernames, u)
      # randomly pick user other than yourself
      Enum.random(tempUserList)
    end)
  end

  def getTweetList(usernames, num_tweets) do
    # num tweets a user has to make
    tweetList = Enum.to_list(1..num_tweets)

    Enum.map(usernames, fn u ->
      tempUserList = List.delete(usernames, u)

      Enum.map(tweetList, fn _ ->
        # pick someone (not yourself) to send a tweet to
        Simulator.Helper.make_tweet(tempUserList)
      end)
    end)
  end

  # num_user = 10
  # peak_frequency = 9
  # Simulator.Helper.load_tweet_collection
  # usernames = Simulator.Helper.getUsernames(10)
  # zipfDistribution = [9, 5, 3, 3, 2, 2, 2, 2, 1, 1]
  # Simulator.Helper.getTweetListZipf(usernames, zipfDistribution)
  def getTweetListZipf(usernames, zipfDistribution) do
    Enum.map(Enum.zip(usernames, Enum.to_list(0..(Kernel.length(usernames) - 1))), fn {u, i} ->
      # pick someone (not yourself) to send a tweet to
      tempUserList = List.delete(usernames, u)
      numTweetsForUser = zipfDistribution |> Enum.at(i)

      Enum.map(Enum.to_list(1..numTweetsForUser), fn _ ->
        Simulator.Helper.make_tweet(tempUserList)
      end)
    end)
  end

  # commands to debug
  # num_user = 10
  # peak_frequency = 9
  # Simulator.Helper.load_tweet_collection
  # usernames = Simulator.Helper.getUsernames(10)
  # Simulator.Helper.getFollowingListZipf(usernames, num_user, peak_frequency)

  def getFollowingListZipf(usernames, num_user, peak_frequency) do
    # Note: every user follows at least 1 person

    if peak_frequency > num_user do
      Process.exit(self(), "ERROR: peak_frequency must be less than number of users.")
    end

    # Check to make sure peak_frequency < num_user
    peak_frequency =
      if peak_frequency == num_user do
        IO.puts("WARNING: peak-frequency == number of users. Reducing peak-frequency by 1.")
        peak_frequency - 1
      else
        peak_frequency
      end

    # Get distribution: list of number of followers each user has
    follower_distribution =
      Enum.map(Enum.to_list(1..num_user), fn x ->
        Kernel.ceil(peak_frequency / x)
      end)

    ## Need to convert follower number into following list ##

    # Get the last user and make the first user follow them (edge condition)
    currUser = usernames |> Enum.at(-1)
    # Initialize empty following list of lists and insert edge case user
    following_list = List.duplicate([], num_user - 1)
    following_list = List.insert_at(following_list, 0, [currUser])

    # start loop
    following_list =
      while(num_user - 2, num_user, usernames, follower_distribution, following_list)

    # end loop

    {following_list, follower_distribution}
  end

  def makeZipfListForOneUser(numBlanks, username, numRepeats) do
    Enum.map(Enum.to_list(0..(numRepeats + numBlanks - 1)), fn x ->
      []
      |> append_if_true(x <= numBlanks, [])
      |> append_if_true(x >= numBlanks, [username])
      |> Enum.reverse()
    end)
  end

  # took this function from elixir forums
  defp append_if_true(list, true, item), do: list ++ item
  defp append_if_true(list, _, _), do: list

  def while(x, num_user, usernames, follower_distribution, following_list_old) when x >= 0 do
    # Get amount of following people from zipf distribution
    amountOfPeopleForFollowing = follower_distribution |> Enum.at(x)
    # Get corresponding user to set following list
    currUser = Enum.at(usernames, x)
    # Set following list
    following_list_new =
      Simulator.Helper.makeZipfListForOneUser(
        num_user - amountOfPeopleForFollowing,
        currUser,
        amountOfPeopleForFollowing
      )

    # Pairwise merging lists
    zipped = Enum.zip(following_list_old, following_list_new)
    # Merge contiguous following lists together, recursively.
    combined =
      Enum.map(zipped, fn x ->
        list = Tuple.to_list(x)
        leftSide = list |> Enum.at(0)
        rightSide = list |> Enum.at(1)
        leftSide ++ rightSide
      end)

    # Recursive call - only changing index value: x and updating following_list
    while(x - 1, num_user, usernames, follower_distribution, combined)
  end

  def while(x, _, _, _, combined) when x == -1 do
    combined
  end
end
