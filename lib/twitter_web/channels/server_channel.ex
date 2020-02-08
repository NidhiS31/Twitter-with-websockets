defmodule Twitter.ServerChannel do
  use Phoenix.Channel

  def join("lobby", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("registerUser", payload, socket) do
      userName = Map.get(payload, "userName")
      password = Map.get(payload, "password")
      :ets.insert(:usersRegister, {userName, password})
      # push socket, "Register", %{registerStatus: "New User Registration Successful!!", userName: userName}
      {:noreply, socket}
  end

  def handle_in("login", payload, socket) do
      userName = payload["userName"]
      password = payload["password"]
      userTuple = :ets.lookup(:usersRegister, userName)
      userPassword  = if (userTuple != []) do
                          userPassword = elem(Enum.at(userTuple,0),1)
                          userPassword
                      else 
                          ""
                      end
      
      if userPassword == password do
          :ets.insert(:socketsMap, {userName, socket})
          push socket, "Login", %{loginStatus: "User Login Successful", userName: userName}
      else 
          push socket, "Login", %{loginStatus: "User Login Unuccessful", userName: userName}
      end
      {:noreply, socket}
  end

  def handle_in("userTweet", payload, socket) do

      IO.inspect "The User received a TWEET"

      userName = Map.get(payload, "userName")
      tweetMessage = Map.get(payload, "tweetMessage")

      tweetID = :ets.info(:tweetsRegister)[:size]

      :ets.insert(:socketsMap, {userName, socket})
      :ets.insert(:tweetsRegister, {tweetID, userName, tweetMessage, true, nil})

      if (tweetMessage != nil) do
        tweetContentList = String.split(tweetMessage, " ")
        hashTagsList = getHashtagList(tweetContentList,[])
        mentionsList = getMentionsList(tweetContentList, [])
        Enum.each(hashTagsList, fn index -> updateHashtags(index, tweetID) end)
        Enum.each(mentionsList, fn index -> updateUserMentions(index, tweetID) end)
              
        followersList = getFollowerUsers(userName)
        
        newpayload = %{tweetUser: userName, tweetString: tweetMessage, isRetweet: false, originalTweetUser: nil}      
        Enum.each(followersList, fn followerUser -> receiveTweetByFollower(followerUser, tweetID, userName, newpayload) end) 
        Enum.each(mentionsList, fn mentionedUser -> receiveTweetByFollower(mentionedUser, tweetID, userName, newpayload) end)
      end

      {:noreply, socket}
  end

    def handle_in("userRetweet", payload, socket) do
        
        IO.inspect("THe User Tweet was RETWEETED")

      userName = Map.get(payload, "userName")
      tweetMessage = Map.get(payload, "tweetMessage")
      originalTweeter = Map.get(payload, "originalTweeter")

      tweetID = :ets.info(:tweetsRegister)[:size]
      :ets.insert(:socketsMap, {userName, socket})
      :ets.insert(:tweetsRegister, {tweetID, userName, tweetMessage, true, originalTweeter})

      if (tweetMessage != nil) do
      tweetContentList = String.split(tweetMessage, " ")
      hashTagsList = getHashtagList(tweetContentList,[])
      mentionsList = getMentionsList(tweetContentList, [])
      followersList = getFollowerUsers(userName)

      Enum.each(hashTagsList, fn index -> updateHashtags(index, tweetID) end)
      Enum.each(mentionsList, fn index -> updateUserMentions(index, tweetID) end)

      newpayload = %{tweetUser: userName, tweetString: tweetMessage, isRetweet: true, originalTweetUser: originalTweeter}

      Enum.each(followersList, fn followerUser -> receiveTweetByFollower(followerUser, tweetID, userName, newpayload) end)
      Enum.each(mentionsList, fn mentionedUser -> receiveTweetByFollower(mentionedUser, tweetID, userName, newpayload) end)
      end
      {:noreply, socket}
  end

  def handle_in("followUser", payload, socket) do
      followerUserName = Map.get(payload, "followUserName")
      userName = Map.get(payload, "userName")
      :ets.insert(:socketsMap, {userName, socket})
      
      followerMap = if :ets.lookup(:followersRegister, followerUserName) == [] do
                      MapSet.new
                  else
                      [{_, followerSet}] = :ets.lookup(:followersRegister, followerUserName)
                      followerSet
                  end
  
      followerMap = MapSet.put(followerMap, userName)    
      :ets.insert(:followersRegister, {followerUserName, followerMap})
  
      followsMapSet = if :ets.lookup(:followingRegister, userName) == [] do
                          MapSet.new
                      else
                       [{_, followingSet}] = :ets.lookup(:followingRegister, userName)
                       followingSet
                      end 
  
      followsMapSet = MapSet.put(followsMapSet, followerUserName)
      :ets.insert(:followingRegister, {userName, followsMapSet})

      push socket, "updateFollowingList", %{userfollowing: followsMapSet} 
      {:noreply, socket}
  end

  def handle_in("querySubscribedToTweets", payload, socket) do

      userName = Map.get(payload, "userName")        
      followsMapSet = if :ets.lookup(:followingRegister, userName) == [] do
                          MapSet.new
                      else
                       [{_, followingSet}] = :ets.lookup(:followingRegister, userName)
                       followingSet
                      end 

      subscribedToTweets = fetchSubscribedToTweets(followsMapSet)

      push socket, "getSubscribedToTweets", %{tweets: subscribedToTweets}
      {:noreply, socket}  
  end

  def handle_in("queryMentionedTweets", payload, socket) do
      userName = Map.get(payload, "userName")
      mentionsMapSet =    if :ets.lookup(:mentionsRegister, userName) == [] do
                            MapSet.new
                          else
                            [{_, mentionsMapSet}] = :ets.lookup(:mentionsRegister, userName)
                            mentionsMapSet
                          end
      mentionedList = MapSet.to_list(mentionsMapSet)
      count = length(mentionedList)
      mentionedTweets = getMentionedTweets(mentionedList, count, [])

      push socket, "getMentionedTweets", %{tweetsString: mentionedTweets}
      {:noreply, socket}
  end

  def handle_in("queryHashtagsTweets", payload, socket) do
      hashtag = Map.get(payload, "hashtag")

      hashtagMapSet = if :ets.lookup(:hashtagsRegister, hashtag) == [] do
                        MapSet.new
                      else
                        [{_, hashtagMapSet}] = :ets.lookup(:hashtagsRegister, hashtag)
                        hashtagMapSet
                      end

      hashtagList = MapSet.to_list(hashtagMapSet)
      count = length(hashtagList)  
      hashtagTweets = getHashtagsTweets(hashtagList, count, [])

      push socket, "getHashtagsTweets", %{tweetString: hashtagTweets}
      {:noreply, socket}
  end    

  def handle_in("updateSocket", payload, socket) do
      userName = Map.get(payload, "userName")
      :ets.insert(:socketsMap, {userName, socket})
      {:noreply, socket}
  end

  def getDetails(tableName, key, indexOfKey) do
    tableName = String.to_atom(tableName)
    resultOfQuery = :ets.lookup(tableName, key)
    resultlist = []
    resultlist =    if length(resultOfQuery) > 0 do
                        resultlist = elem(Enum.at(resultOfQuery, 0), indexOfKey)
                        resultlist
                    else
                        resultlist
                    end
                    resultlist
  end

  def getHashtagsTweets(hashTagsList, count, hashtagTweets) when count > 0 do
      index = Enum.at(hashTagsList, count)
      [{index, userName, tweetMessage, isRetweet, originalTweeter}] = :ets.lookup(:tweetsRegister, index)
      hashtagTweets = List.insert_at(hashtagTweets, 0, %{tweetID: index, tweetUser: userName, tweet: tweetMessage, isRetweet: isRetweet, originalTweetUser: originalTweeter})
      getHashtagsTweets(hashTagsList, count - 1, hashtagTweets)
  end

  def getHashtagsTweets([], hashtagTweets) do
      hashtagTweets
  end

  def getMentionedTweets(mentionedList, count, mentionedTweets) when count >= 0 do
      index = Enum.at(mentionedList, count)
      [{index, userName, tweetMessage, isRetweet, originalTweeter}] = :ets.lookup(:tweetsRegister, index)
      mentionedTweets = List.insert_at(mentionedTweets, 0, %{tweetID: index, tweetUser: userName, tweet: tweetMessage, isRetweet: isRetweet, originalTweetUser: originalTweeter})
      getMentionedTweets(mentionedList, count - 1, mentionedTweets)
  end

  def getMentionedTweets(_mentionedList, count, mentionedTweets) when count < 0 do
      mentionedTweets
  end

  def getHashtagList(tweetContentList, hashtagList) when tweetContentList != [] do
      [head | tail] = tweetContentList
      if (String.first(head) == "#") do
          hashtagList = List.insert_at(hashtagList, 0, head)
          getHashtagList(tail, hashtagList)
      else
          getHashtagList(tail, hashtagList)
      end
  end

  def getHashtagList(_tweetContentList, hashtagList) do
      hashtagList
  end
  def getMentionsList(tweetContentList,mentionsList) when tweetContentList != [] do
      [head | tail] = tweetContentList
      if (String.first(head) == "@") do
          [_,user] = String.split(head, "@")
          mentionsList = List.insert_at(mentionsList, 0, user)
          getMentionsList(tail, mentionsList)
      else
          getMentionsList(tail, mentionsList)
      end
  end

  def getMentionsList(_tweetContentList, mentionsList) do
      mentionsList
  end

  def updateHashtags(hashtag, tweetID) do
      tweets = 
      if :ets.lookup(:hashtagsRegister, hashtag) == [] do
          tweet = MapSet.new
          MapSet.put(tweet, tweetID)
      else
          [{_,tweet}] = :ets.lookup(:hashtagsRegister, hashtag)
          MapSet.put(tweet, tweetID)
      end

      :ets.insert(:hashtagsRegister, {hashtag, tweets})
  end

  def updateUserMentions(mentionedUserName, tweetID) do
      tweets = 
      if :ets.lookup(:mentionsRegister, mentionedUserName) == [] do
          tweet = MapSet.new
          MapSet.put(tweet, tweetID)
      else
          [{_,tweet}] = :ets.lookup(:mentionsRegister, mentionedUserName)
        MapSet.put(tweet, tweetID)
      end

      :ets.insert(:mentionsRegister, {mentionedUserName, tweets})
  end

  def getFollowerUsers(userName) do
      followerList =  if Enum.at(:ets.lookup(:followersRegister, userName),0) == nil do
                          []
                      else
                          MapSet.to_list(elem(Enum.at(:ets.lookup(:followersRegister, userName),0), 1))
                      end
      followerList
  end

  def receiveTweetByFollower(follower, _tweetID, _userName, payload) do
      followerUser = elem(Enum.at(:ets.lookup(:socketsMap, follower),0), 1)
      push followerUser,  "getFollowingUserTweet", payload
  end

  def fetchSubscribedToTweets(followsMapSet) do
      subscribedToTweetsList =for followingUser <- MapSet.to_list(followsMapSet) do
                              tweetsList = (:ets.match(:tweetsRegister, {:_, followingUser, :"$1", :_, :_}))
                              tweetsList = List.flatten(tweetsList)
                              Enum.map(tweetsList, fn tweetMessage -> %{tweetUser: followingUser, tweetString: tweetMessage} end)
                          end
      subscribedToTweets = List.flatten(subscribedToTweetsList)
      subscribedToTweets
  end

end