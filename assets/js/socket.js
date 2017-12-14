// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.

socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("tweeter", {});

$(document).ready(function() { channel.push('refresh_socket', { username: userID });
});

if(document.getElementById("signup"))
{
  let signup_username = $('#signup_username');
  let signup_password    = $('#signup_password');
 
  document.getElementById("signup").onclick = function() {
  channel.push('register_account', { username: signup_username.val(), password: signup_password.val() });
  alert("Registered user: "+ signup_username.val());
  signup_username.val('');
  signup_password.val('');
};

if(document.getElementById("signin"))
  {
    let username = $('#username');
    let password    = $('#password');
    document.getElementById("signin").onclick = function() {
    window.location.href = 'http://localhost:4000/dashboard' + '#' + username.val();
    channel.push('login', { username: username.val(), password: password.val() });
  };
  }

}
if(document.getElementById("tweetButton"))
{
  $(document).ready(function() { channel.push('refresh_socket', { username: userID });
});

  let tweet = $('#tweetValue');
  var user_name=  window.location.hash.substring(1)
  document.getElementById("tweetButton").onclick = function() {
  channel.push('tweet', { tweet: tweet.val() , username: user_name });
  tweet.val('');
};
}

if(document.getElementById("followButton"))
{
  let selfId = $('#selfId');
  let to_user = $('#to_user');
  var userID =  window.location.hash.substring(1)
  
  document.getElementById("followButton").onclick = function() {  
  channel.push('subscribe', { to_user: to_user.val(), selfId: userID });
  alert("Subscribed to: "+ to_user.val());
  to_user.val('');
};
}

if(document.getElementById("userTweetsButton"))
  {
    var userID =  window.location.hash.substring(1)
    
    document.getElementById("userTweetsButton").onclick = function() {
    channel.push('queryUserTweets', { username: userID });
  };
  }

if(document.getElementById("hashtagButton"))
{
  let h_tag = $('#hashtag');
  var user_name =  window.location.hash.substring(1)
  document.getElementById("hashtagButton").onclick = function() {
  channel.push('query_hashtag', { username: user_name, hashtag: h_tag.val() });
  h_tag.val('');
};
}

channel.on('Login', payload => {
  let list    = $('#message-list');
  list.append(`<b>${"Registered:" || 'Anonymous'}:</b> ${payload.login_status}<br>`);
  list.prop({scrollTop: list.prop("scrollHeight")});
});

if(document.getElementById("myMentionsButton"))
  {
    var user_name =  window.location.hash.substring(1)
    
    document.getElementById("myMentionsButton").onclick = function() {
    channel.push('query_user_mentions', { username: user_name });
  };
  }

channel.on('GetMentions', payload => {
  var area   = document.getElementById("mentionsArea");
  var tweets_arr = payload.tweets;
  var len = tweets_arr.length;
  
  area.innerHTML = '';
  
  for (var i = 0; i < len; i++) {
    area.innerHTML+=(`${payload.tweets[i].tweeter} tweeted: ${payload.tweets[i].tweet}`);
    area.innerHTML+="<br>";
  }
  area.prop({scrollTop: area.prop("scrollHeight")});
});

channel.on('GetUserTweets', payload => {
  var area   = document.getElementById("userTweetsArea");
  var tweets_arr = payload.tweets;
  var len = tweets_arr.length;
  
  area.innerHTML = '';
  
  for (var i = 0; i < len; i++) {
    area.innerHTML+=(`${payload.tweets[i].tweeter} tweeted: ${payload.tweets[i].tweet}`);
    area.innerHTML+="<br>";
  }
  area.prop({scrollTop: area.prop("scrollHeight")});
});


  
  if(document.getElementById("retweetButton"))
  {
    document.getElementById("retweetButton").onclick = function() {
      var user_name =  window.location.hash.substring(1)
      var user = $('input[name=radioTweet]:checked').attr("user");
      var tweet = $('input[name=radioTweet]:checked').attr("tweet");
      
      channel.push('retweet', { username: user_name, retweeted_from: user, tweet: tweet });
      alert("Retweeted: "+ tweet);
  };
  }

channel.on('GetHashtags', payload => {
  var hashspace   = document.getElementById("hashtagArea");
  var tweets_arr2 = payload.tweets;
  var len2 = tweets_arr2.length;
  
  hashspace.innerHTML = '';
  
  for (var i = 0; i < len2; i++) {
    hashspace.innerHTML+=(`${payload.tweets[i].tweeter} tweeted: ${payload.tweets[i].tweet}`);
    hashspace.innerHTML+="<br>";
  }
  hashspace.prop({scrollTop: area.prop("scrollHeight")});
});

channel.on ('ReceiveTweet', payload => {
  let tweet_list = $('#tweet-list');
  var input_button = document.createElement("INPUT");
  
  input_button.setAttribute('type', 'radio');
  input_button.setAttribute('name', 'radioTweet');
  input_button.setAttribute('user', `${payload.username}`);
  input_button.setAttribute('tweet', `${payload.tweet}`);
  tweet_list.append(input_button);
  if(`${payload.reTweet}` == "Y") {
    tweet_list.append(`<b>${payload.username}</b> re-tweeted <b>${payload.tweet}</b> from ${payload.reTweetedFrom}<br>`);
  }
  else {
    tweet_list.append(`<b>${payload.username} tweeted:</b> ${payload.tweet}<br>`);
  }
  tweet_list.prop({scrollTop: tweet_list.prop("scrollHeight")});
});

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket