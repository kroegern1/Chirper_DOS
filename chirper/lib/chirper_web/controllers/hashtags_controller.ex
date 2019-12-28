defmodule ChirperWeb.HashtagsController do
  use ChirperWeb, :controller

  def index(conn, params) do
    hashtag = params["hashtag"]
    results = GenServer.call(Chirper.Engine.Server, {:query, hashtag})
    IO.inspect(results)
    render(conn, "hashtagSearch.html", hashtag: hashtag, results: results)
  end

end
