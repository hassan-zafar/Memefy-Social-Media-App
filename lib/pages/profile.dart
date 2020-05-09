import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';

class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserID = currentUser?.id;
  String postOrientation = "grid";
  bool isLoading = false;
  bool isFollowing = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  @override
  void initState() {
    super.initState();
    getProfilePost();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserID)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followersCount = snapshot.documents.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePost() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/no_content.svg',
              height: 260.0,
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "No Posts",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  fontSize: 40.0,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == "grid") {
      List<GridTile> gridTiles = [];
      posts.forEach((posts) {
        gridTiles.add(GridTile(child: PostTile(posts)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        physics: NeverScrollableScrollPhysics(),
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        children: gridTiles,
      );
    } else if (postOrientation == 'list') {
      return Column(
        children: posts,
      );
    }
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14.0,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(
                  currentUserID: currentUserID,
                )));
  }

  Container buildButton({
    String text,
    Function function,
  }) {
    return Container(
      padding: EdgeInsets.only(top: 2),
      child: FlatButton(
        onPressed: function,
        child: Container(
          alignment: Alignment.center,
          width: 210,
          height: 35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: isFollowing ? Colors.grey : Colors.blue,
            border: Border.all(color: isFollowing ? Colors.white : Colors.blue),
          ),
          child: Text(
            text,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isFollowing ? Colors.black : Colors.white),
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    //Will show different screen for LoggedIn user vs Visiting User
    bool isProfileOwner = currentUserID == widget.profileId;
    if (isProfileOwner) {
      return buildButton(
        text: "Edit Profile",
        function: editProfile,
      );
    } else if (isFollowing) {
      return buildButton(text: 'Unfollow', function: handleUnfollowUser);
    } else if (!isFollowing) {
      return buildButton(text: 'Follow', function: handleFollowUser);
    }
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
    });
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserID)
        .setData({});

    followingRef
        .document(currentUserID)
        .collection('userFollowing')
        .document(widget.profileId)
        .setData({});

    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserID)
        .setData({
      'type': 'follow',
      'ownerId': widget.profileId,
      'username': currentUser.username,
      'userId': currentUserID,
      'userProfileImg': currentUser.photoURL,
      'timestamp': timestamp,
    });
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
    });
    //remove Follower
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserID)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
//remove Following
    followingRef
        .document(currentUserID)
        .collection('userFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
//delete activityFeedItem for them
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserID)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  FutureBuilder buildProfileHeader() {
    return FutureBuilder(
      future: userRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 42.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoURL),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followersCount),
                            buildCountColumn("following", followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.only(top: 12.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  user.username,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 4.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  user.displayname,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 2.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  user.bio,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
            icon: Icon(Icons.grid_on),
            color: postOrientation == 'grid' ? Colors.black : Colors.grey,
            onPressed: () => setPostOrientation("grid")),
        IconButton(
            icon: Icon(Icons.list),
            color: postOrientation == 'list' ? Colors.black : Colors.grey,
            onPressed: () => setPostOrientation("list")),
      ],
    );
  }

  // bool get wantKeepAlive => true;
  @override
  Scaffold build(BuildContext context) {
    // super.build(context);
    return Scaffold(
        appBar: header(context, isAppTitle: false, titleText: "Profile"),
        body: ListView(
          children: <Widget>[
            buildProfileHeader(),
            Divider(),
            buildTogglePostOrientation(),
            Divider(
              height: 0.0,
            ),
            buildProfilePosts(),
          ],
        ));
  }
}
