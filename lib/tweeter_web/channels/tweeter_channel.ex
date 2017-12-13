defmodule Tweeter.TweetChannel do
    use Phoenix.Channel
  
    def join("tweeter", _payload, socket) do
      {:ok, socket}
    end

    def handle_in("register_account", payload, socket) do
        user_name = payload["username"]
        password = payload["password"]
        current_time = DateTime.utc_now()
        register_success = :ets.insert_new(:users, {user_name, password, current_time})
        {:noreply, socket}
    end

    def handle_in("login", payload, socket) do
        user_name = payload["username"]
        password = payload["password"]
        current_time = DateTime.utc_now()
        login_pwd = if :ets.lookup(:users, user_name) != [] do
            elem(List.first(:ets.lookup(:users, user_name)), 1)
        else
            ""
        end
        
        if login_pwd == password do
            :ets.insert(:map_of_sockets, {user_name, socket})
            push socket, "Login", %{login_status: "Login successful"}
        else 
            push socket, "Login", %{login_status: "Login unsuccessful"}
        end
        {:noreply, socket}
    end

    def handle_in("logout", payload, socket) do
      user_name = payload["username"]
      :ets.delete(:map_of_sockets, user_name)
      {:noreply, socket}
    end

    def handle_in("update_socket", payload, socket) do
        username = payload["username"]
        :ets.insert(:map_of_sockets, {username, socket})
        {:noreply, socket}
    end

    def handle_in("subscribe", payload, socket) do
        user = payload["username2"]
        follower = payload["selfId"]
        :ets.insert(:map_of_sockets, {follower, socket})

        subscribers = if :ets.lookup(:followers, user) == [] do
            []
          else
            elem(List.first(:ets.lookup(:followers, user)), 1)
          end
          subscribers =  [follower] ++ subscribers
          :ets.insert(:followers, {user, subscribers})
      
          subscribing = if :ets.lookup(:following, follower) == [] do
            []
          else
            elem(List.first(:ets.lookup(:following, follower)), 1)
          end
          subscribing =  [user] ++ subscribing
          :ets.insert(:following, {follower, subscribing})
        {:noreply, socket}
      end

    def handle_in("tweet", payload, socket) do
        user_name = payload["username"]
        tweet = payload["tweetText"]
        :ets.insert(:map_of_sockets, {user_name, socket})
        tweet_id = :ets.info(:tweets)[:size]
        current_time = DateTime.utc_now()
        :ets.insert_new(:tweets, {tweet_id, user_name, tweet, current_time, False, user_name})
    
        hashtags_in_tweet = String.split(tweet, " ") |> Enum.filter(fn word -> String.contains?(word, "#") end)
        for h_tag <- hashtags_in_tweet do
          tweet_ids_of_htag = if :ets.lookup(:hashtags, h_tag) == [] do
            []
          else
            elem(List.first(:ets.lookup(:hashtags, h_tag)), 1)
          end
          tweet_ids_of_htag = [tweet_id] ++ tweet_ids_of_htag
          :ets.insert(:hashtags, {h_tag, tweet_ids_of_htag})
        end
    
        mentions_in_tweet = String.split(tweet, " ") |> Enum.filter(fn word -> String.contains?(word, "@") end)
        for u_mentions <- mentions_in_tweet do
          tweet_ids_of_umen = if :ets.lookup(:user_mentions, u_mentions) == [] do
            []
          else
            elem(List.first(:ets.lookup(:user_mentions, u_mentions)), 1)
          end
          tweet_ids_of_umen = [tweet_id] ++ tweet_ids_of_umen
          :ets.insert(:user_mentions, {u_mentions, tweet_ids_of_umen})
        end
    
        # IO.inspect "Tweet::: User #{user_name} ::: #{tweet}"

        payload = %{username: user_name, tweetText: tweet, reTweet: "N"}   
        broadcast_live_tweets(user_name, payload)
        {:noreply, socket}
    end

    # Broadcast live tweets
    def broadcast_live_tweets(user_name, payload) do
      subscribers = if :ets.lookup(:followers, user_name) == [] do
        []
      else
        elem(List.first(:ets.lookup(:followers, user_name)), 1)
      end

      n_tweets = if :ets.lookup(:num_of_tweets, 1) == [] do
        0
      else
        elem(List.first(:ets.lookup(:num_of_tweets, 1)), 1)
      end

      n_tweets = n_tweets + length(subscribers)
      :ets.insert(:num_of_tweets, {1, n_tweets})

      hour = to_string(elem(elem(:calendar.universal_time(), 1), 0))
      min = to_string(elem(elem(:calendar.universal_time(), 1), 1))
      sec = to_string(elem(elem(:calendar.universal_time(), 1), 2))
      time = hour <> ":" <> min <> ":" <> sec
      IO.inspect "Time: #{time}, Number of tweets: #{n_tweets}"
    
      for f_user <- subscribers do
        if :ets.lookup(:map_of_sockets, f_user) != [] do
          push elem(List.first(:ets.lookup(:map_of_sockets, f_user)), 1),  "ReceiveTweet", payload
        end
      end
    end
    
    def handle_in("retweet", payload, socket) do
      user_name = payload["username"]
      retweeted_from = payload["retweeted_from"]
      tweet = payload["tweetText"]
      tweet_id = :ets.info(:tweets)[:size]
      :ets.insert(:map_of_sockets, {user_name, socket})

      current_time = DateTime.utc_now()
      :ets.insert_new(:tweets, {tweet_id, user_name, tweet, current_time, True, retweeted_from})  
      # IO.inspect "Retweet::: User #{user_name} retweeted #{tweet} from #{retweeted_from}"
  
      payload = %{username: user_name, tweetText: tweet, reTweet: "Y", reTweetedFrom: retweeted_from}
      broadcast_live_tweets(user_name, payload)
      {:noreply, socket}
    end

    def handle_in("query_user_mentions", payload, socket) do
      username = payload["username"]
      user_men = "@" <> username
      list_of_tweet_ids = if :ets.lookup(:user_mentions, user_men) == [] do
        []
      else
        elem(List.first(:ets.lookup(:user_mentions, user_men)), 1)
      end
    
      result = for u_tweet_id <- list_of_tweet_ids do
        list_of_tweets = List.to_tuple(List.flatten(:ets.match(:tweets, {u_tweet_id, :"$1", :"$2", :_, False, :_})))
        u_user = elem(list_of_tweets, 0)
        u_tweet = elem(list_of_tweets, 1)
        %{tweetID: u_tweet_id, tweeter: u_user, tweet: u_tweet}
      end
        
      result = List.flatten(result)
      # IO.inspect "Get my mentions ::: #{username}"
      # IO.inspect result
      push socket, "GetMentions", %{tweets: result}
      {:noreply, socket}
    end

    def handle_in("query_hashtag", payload, socket) do
      hashtag = payload["hashtag"]
      user_name = payload["username"]
      tweet_ids = if :ets.lookup(:hashtags, hashtag) == [] do
        []
      else
        elem(List.first(:ets.lookup(:hashtags, hashtag)), 1)
      end
          
      result = for tweet_id <- tweet_ids do
        list_of_tweets = List.to_tuple(List.flatten(:ets.match(:tweets, {tweet_id, :"$1", :"$2", :_, False, :_})))
        h_user = elem(list_of_tweets, 0)
        h_tweet = elem(list_of_tweets, 1)
        %{tweetID: tweet_id, tweeter: h_user, tweet: h_tweet}
      end
      result = List.flatten(result)
      :ets.insert(:user_recent_hashtags, {user_name, hashtag})
      # IO.inspect "Search hashtag ::: #{user_name}, #{hashtag}"
      # IO.inspect result
      push socket, "GetHashtags", %{tweets: result}
      {:noreply, socket}
    end

    def handle_in("queryUserTweets", payload, socket) do
      user_name = payload["username"]
      subscribing = if :ets.lookup(:following, user_name) == [] do
        []
      else
        elem(List.first(:ets.lookup(:following, user_name)), 1)
      end
      
      result = for f_user <- subscribing do
        list_of_tweets = :ets.match(:tweets, {:"$1", f_user, :"$2", :_, :_, :_})
        #IO.inspect list_of_tweets
        # Enum.map(list_of_tweets, fn tweet_id, tweet -> {tweetID: tweet_id, tweeter: f_user, tweet: tweet} end)
        if list_of_tweets != [] do
          for x <- list_of_tweets do
              x_tweet_id = List.first(x)
              x_tweet = List.last(x)
              x_user = f_user
              %{tweetID: x_tweet_id, tweeter: x_user, tweet: x_tweet}
          end
        else
          %{}
        end
      end
      result = List.flatten(result)
      push socket, "GetUserTweets", %{tweets: result}
      # IO.inspect "Query user tweets ::: #{user_name}"
      # IO.inspect result
      {:noreply, socket}
    end

    def handle_in("retweetRandom", payload, socket) do
      user_name = payload["username"]
      :ets.insert(:map_of_sockets, {user_name, socket})
      subscribing = if :ets.lookup(:following, user_name) == [] do
        []
      else
        elem(List.first(:ets.lookup(:following, user_name)), 1)
      end

      result = for f_user <- subscribing do
        list_of_tweets = :ets.match(:tweets, {:"$1", f_user, :"$2", :_, :_, :_})
        tweet_list = for x <- list_of_tweets do
              x_tweet_id = List.first(x)
              x_tweet = List.last(x)
              x_user = f_user
              {x_tweet_id, x_user, x_tweet}
          end
      end
      
      result = List.flatten(result)

      if result != [] do
        random_tweet = Enum.random(result)      
        retweeted_from = elem(random_tweet, 1)
        tweet = elem(random_tweet, 2)
        tweet_id = :ets.info(:tweets)[:size]
      
        current_time = DateTime.utc_now()
        :ets.insert_new(:tweets, {tweet_id, user_name, tweet, current_time, True, retweeted_from})  
        # IO.inspect "Retweet::: User #{user_name} retweeted #{tweet} from #{retweeted_from}"
  
        payload = %{username: user_name, tweetText: tweet, reTweet: "Y", reTweetedFrom: retweeted_from}
        broadcast_live_tweets(user_name, payload)
      end
      {:noreply, socket}
    end

  end