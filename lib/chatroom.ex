defmodule Chatroom do
  use Phoenix.ChannelTest
  @endpoint ChatroomWeb.Endpoint
  @moduledoc """
  Chatroom keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
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
    IO.inspect list_of_socket_ids
    # subscribe_all_user = Tweeter.subscribe_all_user(no_of_clients, server_ip)
    # start_simulation(no_of_clients, list_of_static_hashtags, [], client_ip, server_ip)

    :timer.sleep(:infinity)
  end  
end
