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
let channel = socket.channel("lobby", {});

/*message.on('keypress', event => {
  if (event.keyCode == 13) {
    channel.push('register_account', { name: name.val(), message: message.val() });
    message.val('');
  }
});*/

$(document).ready(function() { channel.push('update_socket', { username: userID });
});

if(document.getElementById("signup"))         // use this if you are using id to check
{
  let new_username = $('#new_username');
  let new_password    = $('#new_password');
  //window.location = "http://localhost:4000/dashboard.html?temp=" + new_username;
 
  document.getElementById("signup").onclick = function() {
 
    //console.log(window.location.href);
  channel.push('register_account', { username: new_username.val(), password: new_password.val() });
  
  
  //location.href="home.html"
};
}
if(document.getElementById("btnTweet"))         // use this if you are using id to check
{
  $(document).ready(function() { channel.push('update_socket', { username: userID });
});

  let tweetText    = $('#tweetContent');
  var userID =  window.location.hash.substring(1)
  document.getElementById("btnTweet").onclick = function() {
  channel.push('tweet', { tweetText: tweetText.val() , username: userID });
};
}

if(document.getElementById("btnFollow"))         // use this if you are using id to check
{
  let selfId = $('#selfId');
  let username2 = $('#username2');
  var userID =  window.location.hash.substring(1)
  //let username_orig = Request.querystring["temp"];
  //var text =
  
  document.getElementById("btnFollow").onclick = function() {
   console.log("user" + userID);
   console.log("posting subscribe.");
  
  channel.push('subscribeTo', { username2: username2.val(), selfId: userID });
};
}

if(document.getElementById("btnMyMentions"))         // use this if you are using id to check
{
  var userID =  window.location.hash.substring(1)
  
  document.getElementById("btnMyMentions").onclick = function() {
  channel.push('getMyMentions', { username: userID });
};
}

if(document.getElementById("btnRetweet"))         // use this if you are using id to check
{
  document.getElementById("btnRetweet").onclick = function() {
    var userID =  window.location.hash.substring(1)
    var user = $('input[name=radioTweet]:checked').attr("user");
    var tweet = $('input[name=radioTweet]:checked').attr("tweet");
    //document.getElementById("btnMyMentions").onclick = function() {
    channel.push('retweet', { username: userID, retweeted_from: user, tweetText: tweet });
};
}

if(document.getElementById("btnUserTweets"))         // use this if you are using id to check
  {
    var userID =  window.location.hash.substring(1)
    
    document.getElementById("btnUserTweets").onclick = function() {
    channel.push('queryUserTweets', { username: userID });
  };
  }

if(document.getElementById("btnhashtag"))         // use this if you are using id to check
{
  let hash = $('#hashtag');
  var userID =  window.location.hash.substring(1)
  document.getElementById("btnhashtag").onclick = function() {
  channel.push('tweetsWithHashtag', { username: userID, hashtag: hash.val() });
};
}

if(document.getElementById("signin"))         // use this if you are using id to check
{
  let username = $('#username');
  let password    = $('#password');
document.getElementById("signin").onclick = function() {
  window.location.href = 'http://localhost:4000/dashboard' + '#' + username.val();
  channel.push('login', { username: username.val(), password: password.val() });
  //  location.href = "http://localhost:4000/dashboard";
};
}

/*if(document.getElementByTagName("button-retweet"))        // use this if you are using id to check
{
  document.getElementByTagName("button-retweet").onclick = function() {
  console.log("tweet" + self.g);
  console.log("user" + user.val());
 
 //channel.push('subscribeTo', { username2: username2.val(), selfId: userID });
};
}*/


/*channel.on('Registered', payload => {
  list.append(`<b>${"Registered:" || 'Anonymous'}:</b> ${payload.name}<br>`);
  list.prop({scrollTop: list.prop("scrollHeight")});
});*/

channel.on('Login', payload => {
  //alert(`${payload.login_status}`)
  let list    = $('#message-list');
  list.append(`<b>${"Registered:" || 'Anonymous'}:</b> ${payload.login_status}<br>`);
  list.prop({scrollTop: list.prop("scrollHeight")});
});

channel.on ('ReceiveTweet', payload => {
  //alert(`${payload.login_status}`)
  let tweet_list    = $('#tweet-list');
  var btn = document.createElement("INPUT");
  btn.setAttribute('type', 'radio');
  btn.setAttribute('name', 'radioTweet');
  btn.setAttribute('user', `${payload.username}`);
  btn.setAttribute('tweet', `${payload.tweetText}`);
  //btn.innerHTML = 'RETWEET';
  tweet_list.append(btn);
  console.log(`${payload.tweetText}`)
  console.log(`${payload.reTweet}`)
  if(`${payload.reTweet}` == "Y") {
    tweet_list.append(`<b>${payload.username}</b> re-tweeted <b>${payload.tweetText}</b> from ${payload.reTweetedFrom}<br>`);
  }
  else {
    tweet_list.append(`<b>${payload.username} tweeted:</b> ${payload.tweetText}<br>`);
  }
  tweet_list.prop({scrollTop: tweet_list.prop("scrollHeight")});
});

channel.on('ReceiveMentions', payload => {
  var area   = document.getElementById("mentionsArea");
  var myTweets = payload.tweets;
  var arrayLength = myTweets.length;
  area.innerHTML = '';
  for (var i = 0; i < arrayLength; i++) {
    area.innerHTML+=(`${payload.tweets[i].tweeter} tweeted: ${payload.tweets[i].tweet}`);
    area.innerHTML+="<br>";
  }
  area.prop({scrollTop: area.prop("scrollHeight")});
});

channel.on('ReceiveUserTweets', payload => {
  var area   = document.getElementById("userTweetsArea");
  var myTweets = payload.tweets;
  var arrayLength = myTweets.length;
  area.innerHTML = '';
  for (var i = 0; i < arrayLength; i++) {
    area.innerHTML+=(`${payload.tweets[i].tweeter} tweeted: ${payload.tweets[i].tweet}`);
    area.innerHTML+="<br>";
  }
  area.prop({scrollTop: area.prop("scrollHeight")});
});

channel.on('ReceiveHashtags', payload => {
  var hasharea   = document.getElementById("hashtagArea");
  var myTweets2 = payload.tweets;
  var arrayLength2 = myTweets2.length;
  hasharea.innerHTML = '';
  for (var i = 0; i < arrayLength2; i++) {
    hasharea.innerHTML+=(`${payload.tweets[i].tweeter} tweeted: ${payload.tweets[i].tweet}`);
    hasharea.innerHTML+="<br>";
  }
  hasharea.prop({scrollTop: area.prop("scrollHeight")});
});

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket