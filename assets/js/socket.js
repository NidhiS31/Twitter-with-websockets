import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("lobby", {});

$(document).ready(function() { channel.push('updateSocket', { userName: userName});
});

if(document.getElementById("signup"))
{
  let new_username = $('#new_username');
  let new_password    = $('#new_password');

  document.getElementById("signup").onclick = function() {
  channel.push('registerUser', { userName: new_username.val(), password: new_password.val() });
};
}

if(document.getElementById("signin"))
{
  let userName = $('#username');
  let password    = $('#password');
  document.getElementById("signin").onclick = function() {
  channel.push('login', { userName: userName.val(), password: password.val() });
};
}

if(document.getElementById("btnFollow"))
{
  let userName = $('#userName');
  let followerUserName = $('#followerUser');
  var userName =  window.location.hash.substring(1)
  document.getElementById("btnFollow").onclick = function() {
  channel.push('followUser', { followerUserName: followerUser.val(), userName: userName});
};
}

if(document.getElementById("btnTweet"))
{
  $(document).ready(function() {
  channel.push('updateSocket', {userName: userName });
});

  let tweetString  = $('#tweetString');
  var userName =  window.location.hash.substring(1)
  document.getElementById("btnTweet").onclick = function() {
  channel.push('userTweet', { tweetString: tweetString.val() , userName: userName });
};
}

if(document.getElementById("btnQueryTweets"))
{
  var userName =  window.location.hash.substring(1)
  document.getElementById("btnQueryTweets").onclick = function() {
  channel.push('querySubscribedToTweets', { userName: userName });
}
};

if(document.getElementById("btnhashtag"))
{
  let hashtag = $('#hashtag');
  document.getElementById("btnhashtag").onclick = function() {
  channel.push('queryHashtagsTweets', { hashtag : hashtag.val()});
};
}

if(document.getElementById("btnMyMentions"))
{
  var userName =  window.location.hash.substring(1)
  document.getElementById("btnMyMentions").onclick = function() {
  channel.push('queryMentionedTweets', { userName: userName });
};
}

if(document.getElementById("btnRetweet"))
{
  document.getElementById("btnRetweet").onclick = function() {
    var userName =  window.location.hash.substring(1)
    var valueradio = $('input[name=radioTweet]:checked').attr("tweet");
    var orginalTweeter = $('input[name=radioTweet]:checked').attr("user");
    channel.push('userRetweet', { userName: userName,  tweetMessage: valueradio, originalTweeter: orginalTweeter});
}};


channel.on('Login', payload => {

  var unlog    = document.getElementById("unlog");
  unlog.innerHTML = '';
  //  if(`${payload.loginStatus}` == "User Login Unuccessful")
  //  {
  //   unlog.innerHTML+= (`<b>User Login Unuccessful. Incorrect UserName or Password!!<br>`);
  //  }
  //  else
  //  {
     unlog.innerHTML = '';
     window.location.href = 'http://localhost:4000/dashboard' + '#' + payload.userName;
  // }
});

channel.on('getFollowingUserTweet', payload => {
  let tweet_list    = $('#tweet-list');
  var btn = document.createElement("INPUT");
  btn.setAttribute('type', 'radio');
  btn.setAttribute('name', 'radioTweet');
  btn.setAttribute('user', `${payload.tweetUser}`);
  btn.setAttribute('tweet', `${payload.tweetString}`);
  tweet_list.append(btn);
  if(`${payload.isRetweet}` == "false")
  {
    tweet_list.append(`<b>${payload.tweetUser} tweeted:</b> ${payload.tweetString}<br>`);
  }
  if(`${payload.isRetweet}` == "true")
  {
    tweet_list.append(`<b>${payload.tweetUser} retweeted ${payload.originalTweetUser}'s post:</b> ${payload.tweetString}<br>`);
  }
  tweet_list.prop({scrollTop: tweet_list.prop("scrollHeight")});
});

channel.on('getMentionedTweets', payload => {
  var area   = document.getElementById("mentionsArea");
  var myTweets = payload.tweetsString;
  var arrayLength = myTweets.length;
  area.innerHTML = '';
  for (var i = 0; i < arrayLength; i++) {
    area.innerHTML+=(`<b>${payload.tweetsString[i].tweetUser} tweeted:</b> ${payload.tweetsString[i].tweet}`);
    area.innerHTML+="<br>";
  }
  $(area).prop({scrollTop: $(area).prop("scrollHeight")});
});

channel.on('getSubscribedToTweets', payload => {
  var area   = document.getElementById("queryArea");
  var myTweets = payload.tweetsString;
  var arrayLength = myTweets.length;
  area.innerHTML = '';
  for (var i = 0; i < arrayLength; i++) {
    area.innerHTML+=(`<b>${payload.tweetsString[i].tweetUser} tweeted:</b> ${payload.tweetsString[i].tweet}`);
    area.innerHTML+="<br>";
  }
  $(area).prop({scrollTop: $(area).prop("scrollHeight")});
});

channel.on('updateFollowingList', payload => {
  var area   = document.getElementById("followsArea");
  var userfollowing = payload.userfollowing;
  var arrayLength = userfollowing.length;
  area.innerHTML = '';
  for (var i = 0; i < arrayLength; i++) {
    area.innerHTML+=(`${payload.userfollowing[i]}`);
   area.innerHTML+="<br>";
  }
$(area).prop({scrollTop: $(area).prop("scrollHeight")});
});

channel.on('queryHashtagsTweets', payload => {
  var hasharea   = document.getElementById("hashtagArea");
  var myTweets2 = payload.tweetString;
  var arrayLength2 = myTweets2.length;
  hasharea.innerHTML = '';
  for (var i = 0; i < arrayLength2; i++) {
    hasharea.innerHTML+=(`<b>${payload.tweetString[i].tweetUser} tweeted:</b> ${payload.tweetString[i].tweet}`);
    hasharea.innerHTML+="<br>";
  }
  $(hasharea).prop({scrollTop: $(hasharea).prop("scrollHeight")});
});

channel.join()
  .receive("ok", resp => { console.log("Joined successfully.", resp) })
  .receive("error", resp => { console.log("Unable to join.", resp) })

export default socket
