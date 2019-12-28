defmodule ChirperWeb.UserSearchController do
  use ChirperWeb, :controller

  def index(conn, params) do
    username = params["uname"]
    profile = GenServer.call(Chirper.Engine.Server, {:get_user_tweets, username})
    numTweets = Kernel.length(profile)
    numFollowing = GenServer.call(Chirper.Engine.Server, {:get_num_following, username})
    numFollowers = GenServer.call(Chirper.Engine.Server, {:get_num_followers, username})
    numMentions = GenServer.call(Chirper.Engine.Server, {:get_num_mentions, username})
    stats = {numTweets, numFollowing, numFollowers, numMentions}
    IO.inspect(numTweets)
    IO.inspect(numFollowing)
    IO.inspect(numFollowers)
    IO.inspect(numMentions)
    render(conn, "userSearch.html", user: username, stats: stats, profile: profile)
  end

end
