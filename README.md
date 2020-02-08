# Project 4.2

**Twitter Clone Implementation**

## Group Members
**Ananda Bhaasita Desiraju - UFID: 40811191,** 
**Nidhi Sharma - UFID: 68431215**

## What's Working
Twitter Clone has been implemented in Elixir using the actor model with the following functionalities. Test cases have been added for all the functionalites.

1. Register account
2. Send tweets 
3. Send tweets with hashtags
4. Send tweets by mentioning another user in tweet
5. Subscribe to user's tweets.
6. Re-tweets
7. Querying tweets by subscribed to 
8. Query tweets with specific hashtags
9. Query tweets in which a user is mentioned
10. Live view of tweets without querying
11. Delete an account

## Bonus Part
12. Live Connection and disconnection of users
13. Zipf Distribution - Adding followers as per zipf distribution

## Execution Instructions
To Compile and Build:
Change directory to twitter
mix deps.get
mix phx.server

To Execute:
mix phx.server

The simulator is working
iex -S mix phx.server
The user functionalities are displayed in the console
