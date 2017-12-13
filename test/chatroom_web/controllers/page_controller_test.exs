import {Socket} from "phoenix"
defmodule ChatroomWeb.PageControllerTest do
  use ChatroomWeb.ConnCase

  # test "GET /", %{conn: conn} do
  #   conn = get conn, "/"
  #   assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  # end

  test "some test" do
    socket_map = 
    for i<- 1..20 do
      new Socket("/socket", {params: {token: window.userToken}})
    end
    IO.inspect socket_map
  end
end
