defmodule Chatroom do
  use Phoenix.ChannelTest
  @endpoint ChatroomWeb.Endpoint
  @delay 5
  @moduledoc """
  Chatroom keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  def get_sum([first | tail], sum) do
    sum = sum + first
    get_sum(tail, sum)
  end

  def get_sum([], sum) do
    sum
  end

  def maintain_connect_disconnect(no_of_clients, active_users, list_of_socket_ids) do
    rand_active = Enum.random(1..no_of_clients)
    users = Enum.to_list(1..no_of_clients)
    non_active_users = users -- active_users
    no_of_active_users = length(active_users)

    IO.inspect active_users
    Process.sleep(500)

    diff_users = if rand_active > no_of_active_users do
      diff = rand_active - no_of_active_users
      diff_users = for _ <- (1..diff) do
        rand_user = Enum.random(non_active_users)
        user_name = "user" <> to_string(rand_user)
        password = "user" <> to_string(rand_user)
        # TODO Store result
        IO.inspect "#{user_name} logged in."
        socket = elem(list_of_socket_ids, (rand_user- 1))
        push socket, "login", %{"username" => user_name, "password" => password}
        rand_user
      end
    else
      diff = no_of_active_users - rand_active
      diff_users = for _ <- (1..diff) do
        rand_user = Enum.random(active_users)
        user_name = "user" <> to_string(rand_user)
        password = "user" <> to_string(rand_user)
        # TODO Store result
        IO.inspect "#{user_name} logged out."
        socket = elem(list_of_socket_ids, (rand_user- 1))
        push socket, "logout", %{"username" => user_name}
        rand_user
      end
    end

    active_users = if rand_active > no_of_active_users do
      active_users ++ diff_users
    else
      active_users -- diff_users
    end

    new_active_users = if rand_active > no_of_active_users do
      diff_users
    else
      []
    end
    [active_users, new_active_users]
  end

  def subscribe_all_user(no_of_clients, list_of_socket_ids) do
    list_of_available_users = List.to_tuple(Enum.to_list(1..no_of_clients))
    harmonic_list = for j <- 1..no_of_clients do
      Float.floor(1/j)
    end
    c = Float.floor(100/get_sum(harmonic_list,0))
    for id <- 1..no_of_clients do
      num_of_sub = round(Float.floor(c/id))
      follower = "user" <> to_string(id)
      IO.inspect "#{follower} ::: #{num_of_sub} subscribers."
      if num_of_sub != 0 do
        subscribe_user(id, Tuple.delete_at(list_of_available_users, (id - 1)), num_of_sub, list_of_socket_ids)
      end
    end
    Process.sleep(500)    
  end

  def subscribe_user(follower_id, list_of_available_users, num_of_sub, list_of_socket_ids) do
    if list_of_available_users != {} do
      rand_id = Enum.random(0..(tuple_size(list_of_available_users)-1))
      follower = "user" <> to_string(follower_id)
      user = "user" <> to_string(elem(list_of_available_users, rand_id))
      follower_socket = elem(list_of_socket_ids, (follower_id- 1))
      push follower_socket, "subscribeTo", %{"username2" => user, "selfId" => follower}

      num_of_sub = num_of_sub - 1
      x = Tuple.delete_at(list_of_available_users, rand_id)
      subscribe_user(follower_id, x, num_of_sub, list_of_socket_ids)
    end
  end

  def start_simulation(no_of_clients, list_of_static_hashtags, active_users, list_of_socket_ids) do
    # Maintain connect and disconnect
    [active_users, new_active_users] = Chatroom.maintain_connect_disconnect(no_of_clients, active_users, list_of_socket_ids)
    Process.sleep(500)

    # Send tweets
    for user_id <- new_active_users do
      user_name = "user" <> to_string(user_id)
      delay = @delay * user_id
      IO.inspect "#{user_name} starts tweeting at delay of #{delay}"
      spawn(fn -> send_tweets(user_id, active_users, list_of_static_hashtags, delay, list_of_socket_ids) end)

      num_of_retweet_users = (25 * no_of_clients)/100
      if user_id < num_of_retweet_users do
        for _ <- 1..5 do
          retweet_id = Enum.random(active_users)
          retweet_user = "user" <> to_string(retweet_id)
          spawn(fn -> retweet(retweet_id, list_of_socket_ids) end)
        end
      end
    end

    Process.sleep(5000)

    if active_users != [] do
      for _ <- 1..5 do
        user_id = Enum.random(active_users)
        user_name = "user" <> to_string(user_id)
        hashtag = Enum.random(list_of_static_hashtags)
        spawn(fn-> query_for_hashtags(user_id, hashtag, list_of_socket_ids) end)
      end
    end

    Process.sleep(5000)
    
    if active_users != [] do
      for _ <- 1..5 do
        user_id = Enum.random(active_users)
        user_name = "user" <> to_string(user_id)
        spawn(fn-> query_for_usermentions(user_id, list_of_socket_ids) end)
      end
    end

    start_simulation(no_of_clients, list_of_static_hashtags, active_users, list_of_socket_ids)

  end

  def retweet(user_id, list_of_socket_ids) do
    user_name = "@user" <> to_string(user_id)
    socket = elem(list_of_socket_ids, (user_id- 1))
    push socket, "retweetRandom", %{"username" => user_name}
  end

  def query_for_usermentions(user_id, list_of_socket_ids) do
    user_name = "@user" <> to_string(user_id)
    socket = elem(list_of_socket_ids, (user_id- 1))
    push socket, "getMyMentions", %{"username" => user_name}
  end

  def query_for_hashtags(user_id, hashtag, list_of_socket_ids) do
    user_name = "@user" <> to_string(user_id)
    socket = elem(list_of_socket_ids, (user_id- 1))
    push socket, "tweetsWithHashtag", %{"username" => user_name, "hashtag" => hashtag}
  end

  def send_tweets(user_id, active_users, list_of_static_hashtags, delay, list_of_socket_ids) do
    user_name = "user" <> to_string(user_id)
    u_men_toss = Enum.random([1, -1])
    hash_toss = Enum.random([1, -1])

    # Add user mentions
    user_mention = if (u_men_toss == 1) do
      user_id = Enum.random(active_users)
      " @user" <> to_string(user_id)
    else
      ""
    end
    # Add hash tags
    hashtag = if (hash_toss == 1) do
      " " <> Enum.random(list_of_static_hashtags)
    else
      ""
    end

    tweet = ((:crypto.strong_rand_bytes(5)|> Base.encode16) |> (binary_part(0, 5))) <> " " <> ((:crypto.strong_rand_bytes(6)|> Base.encode16 |> binary_part(0, 6))) <> " " <> ((:crypto.strong_rand_bytes(7)|> Base.encode16 |> binary_part(0, 7)))
    tweet = tweet <> user_mention <> hashtag
    socket = elem(list_of_socket_ids, (user_id- 1))
    push socket, "tweet", %{"username" => user_name, "tweetText" => tweet}
    Process.sleep(delay)
    send_tweets(user_id, active_users, list_of_static_hashtags, delay, list_of_socket_ids)
  end

  def main(args) do  
      
    [no_of_clients] = args
    no_of_clients = String.to_integer(no_of_clients)
    list_of_static_hashtags = ["#happyme","#gogators ","#cityofjoy","#lifeisgood","#indiacalling"]

    # Register all users
    list_of_socket_ids = for n <- 1..no_of_clients do
      user_name = "user" <> to_string(n)
      password = "user" <> to_string(n)
      # Start the socket driver process
      {:ok, socket} = connect(ChatroomWeb.UserSocket, %{})
      {:ok, _, socket} = subscribe_and_join(socket, "lobby", %{})
      push socket, "register_account", %{"username" => user_name, "password" => password}
      socket
    end

    list_of_socket_ids = List.to_tuple(list_of_socket_ids)
    
    # Subscribe all users
    subscribe_all_user = Chatroom.subscribe_all_user(no_of_clients, list_of_socket_ids)
    start_simulation(no_of_clients, list_of_static_hashtags, [], list_of_socket_ids)
  end  
end
