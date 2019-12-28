# Chirper_DOS
Twitter simulation in Elixir using Phoenix

Problem definition
The goal of this (and the next project) is to implement a Twitter-like engine and (in
part 2) pair up with Web Sockets to provide full functionality.
Specific things you have to do are:
In part I, implement the following functionalities:
1. Register account and delete account
2. Send tweet. Tweets can have hashtags (e.g. #COP5615isgreat) and mentions
(@bestuser). You can use predefines categories of messages for hashtags.
3. Subscribe to user's tweets.
4. Re-tweets (so that your subscribers get an interesting tweet you got by other
means).
5. Allow querying tweets subscribed to, tweets with specific hashtags, tweets in
which the user is mentioned (my mentions).
6. If the user is connected, deliver the above types of tweets live (without querying).
Other considerations:
The client part (send/receive tweets) and the engine (distribute tweets) have to be
in separate processes. Preferably, you use multiple independent client processes
that simulate thousands of clients and a single-engine process.
