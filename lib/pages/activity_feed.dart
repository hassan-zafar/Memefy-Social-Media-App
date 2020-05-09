import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/post_screen.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  getActivityFeed() async {
    QuerySnapshot snapshot = await activityFeedRef
        .document(currentUser.id)
        .collection('feedItems')
        .orderBy(
          'timestamp',
          descending: true,
        )
        .limit(50)
        .getDocuments();
    List<ActivityFeedItem> feedItems = [];
    snapshot.documents.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
    });
    return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, isAppTitle: false, titleText: "Activity Feed"),
      body: Container(
        child: FutureBuilder(
          future: getActivityFeed(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return circularProgress();
            }
            return ListView(
              children: snapshot.data,
            );
          },
        ),
      ),
    );
  }
}

Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String type; //like,comment follow
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;
  final String userId;

  ActivityFeedItem({
    this.username,
    this.type, //like,comment follow
    this.mediaUrl,
    this.postId,
    this.userProfileImg,
    this.commentData,
    this.timestamp,
    this.userId,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      userProfileImg: doc['userProfileImg'],
      postId: doc['postId'],
      commentData: doc['commentData'],
      mediaUrl: doc['mediaUrl'],
      timestamp: doc['timestamp'],
      type: doc['type'],
    );
  }

  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PostScreen(
                  userId: userId,
                  postId: postId,
                )));
  }

  showProfile(BuildContext context, {String profileId}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Profile(
                  profileId: profileId,
                )));
  }

  configureMediaPreview(context) {
    if (type == 'like' || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => showPost(context),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: CachedNetworkImageProvider(mediaUrl),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Text('');
    }
    if (type == 'like') {
      activityItemText = 'liked your Post';
    } else if (type == 'follow') {
      activityItemText = 'started following you';
    } else if (type == 'comment') {
      activityItemText = 'commented: $commentData';
    } else {
      activityItemText = "Error Unknown type '$type'";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          leading: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(userProfileImg),
            ),
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    style: TextStyle(color: Colors.black, fontSize: 15.0),
                    children: [
                      TextSpan(
                          text: username,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' $activityItemText'),
                    ])),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}
