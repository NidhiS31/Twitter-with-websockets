defmodule Client do

    use Phoenix.ChannelTest
    @endpoint TwitterWeb.Endpoint
    
    
    def main(numOfUsers) do
            socketsMap = startUsers(Enum.to_list(1..numOfUsers), %{})
            
            tweetsList = ["This is Twitter clone", "I ate a clock yesterday, it was very time-consuming.", "How do prisoners call each other? On their cell phones!", "The light heart lives long."]
            hashtagsList = ["#COP5615", "#DOS", "#Twitter", "#Elixir", "#UFlorida", "#GoGators", "#ComputerScience"]
            
            Process.sleep(10000)
            twitterHandler(numOfUsers, socketsMap, tweetsList, hashtagsList)
            Process.sleep(20000)
            spawn(fn-> queryMentionedTweetsFunction(numOfUsers, socketsMap) end)
            Process.sleep(9000)
            spawn(fn-> queryHashtagsTweetsFunction(hashtagsList, socketsMap) end)
      end
        
    def startUsers([client | numClients], socketsMap) do

            {:ok, socket} = connect(TwitterWeb.UserSocket, %{})    
            {:ok, _, socket} = subscribe_and_join(socket, "lobby", %{})
        
            payload = %{username: "User" <> Integer.to_string(client), password: "123"}
            
            push socket, "registerUser", payload
            push socket, "login", payload
            socketsMap = Map.put(socketsMap, "User" <> Integer.to_string(client), socket)
            startUsers(numClients, socketsMap)
    end
    
    def startUsers([], socketsMap) do
            socketsMap
    end


    def twitterHandler(numOfUsers, socketsMap, tweetsList, hashtagsList) do
    
        getZipfFollowers(numOfUsers, socketsMap) 
        Process.sleep(9000)
        delay = 3000 
      for userNumber <- 1..numOfUsers do
        userName = "User" <> Integer.to_string(userNumber)
        socket = Map.get(socketsMap,userName)
        spawn(fn -> tweetGenerator(userName, socket, delay * userNumber, tweetsList, numOfUsers, hashtagsList) end)
      end

    end

    def queryMentionedTweetsFunction(numOfUsers, socketsMap) do
        randomUserIDs = for _<- 1..5 do
                            randomUserIDs = Enum.random(1..numOfUsers)
                            randomUserIDs
                        end
    
        for count <- randomUserIDs do
            payload = %{userName: "User"<>Integer.to_string(count)}
            newsocket = Map.get(socketsMap, "User"<>Integer.to_string(count))
            push newsocket, "queryMentionedTweets", payload
        end

        Process.sleep(4000)
        queryMentionedTweetsFunction(numOfUsers, socketsMap)
    end
    
    def queryHashtagsTweetsFunction(hashtagsList, socketsMap) do

        for index <- 1..5 do
            selectedHashtag = Enum.random(hashtagsList)
            payload = %{hashtag: String.trim(selectedHashtag)}
            newsocket = Map.get(socketsMap, "User"<>Integer.to_string(index))
            push newsocket, "queryHashtagsTweets", payload
        end

        Process.sleep(4000)
        queryHashtagsTweetsFunction(hashtagsList, socketsMap)    
    end
        
    def tweetGenerator(userName, socket, delay, tweetsList, numOfUsers,hashtagslist) do
        tweetMessage = Client.getTweetContent(userName, tweetsList, hashtagslist, numOfUsers)
        payload = %{tweetString: tweetMessage , userName: userName}
        push socket, "userTweet", payload
        Process.sleep(delay)            
        tweetGenerator(userName, socket, delay, tweetsList, numOfUsers, hashtagslist)
    end 
    def getZipfFollowers(numOfUsers, socketsMap) do
        
        zipfConstant = getZipfConstant(numOfUsers, 1, 0)
        zipfConstant = (1/zipfConstant) * numOfUsers    
        
        for tweetUser <- 1..numOfUsers do    
                followerUserName = ("User" <> Integer.to_string(Enum.random(1..numOfUsers)))
                userName = ("User" <> Integer.to_string(tweetUser))
                socket = Map.get(socketsMap, followerUserName)
                push socket, "followUser", %{followerUserName: followerUserName, userName: userName}
        end
        
        followersList = for tweetUser <- 1..numOfUsers do
                            {"User" <> Integer.to_string(tweetUser) , round(Float.floor(zipfConstant/tweetUser))}
                        end
        IO.inspect(followersList)
    end

    def getZipfConstant(numOfUsers, count, zipfConstantValue) when count <= numOfUsers do
        zipfConstantValue = zipfConstantValue + (1/count)
        getZipfConstant(numOfUsers, count + 1, zipfConstantValue)
      end
    
      def getZipfConstant(numOfUsers, count, zipfConstantValue) when count > numOfUsers do
        zipfConstantValue
      end
    
    
    def getTweetContent(_userName,tweetsList, hashtagslist, numOfUsers) do
        
        randomTweet = Enum.random(1..Enum.count(tweetsList))
        getTweet = Enum.at(tweetsList, randomTweet - 1)
        
        hashtagList = gethashtagTweets(hashtagslist)
        mentionsList = getMentionsTweets(numOfUsers)

        tweet = getTweet <> List.to_string(hashtagList) <> List.to_string(mentionsList)
        tweet
        end

        def gethashtagTweets(hashtagslist) do
            
            index = Enum.random(0..7)
    
            hashtagList =   if index > 0 do
                                for position <- Enum.to_list(1..index) do
                                    Enum.at(hashtagslist, position - 1)
                                end
                            else
                                []
                            end
            hashtagList
        end
    
        def getMentionsTweets(numOfUsers) do
            numOfMentions = Enum.random(0..5)
            mentionsList =  if numOfMentions > 0 do
                                for _index <- Enum.to_list(1..numOfMentions) do
                                     "@user" <> Integer.to_string(Enum.random(1..numOfUsers)) <> " "
                                end
                            else
                                []
                            end
            mentionsList
        end     
    end