import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;
//  final String userName;
  Comments({this.postId, this.postMediaUrl, this.postOwnerId});
  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        postMediaUrl: this.postMediaUrl,
        postOwnerId: this.postOwnerId,
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;
//  final String userName;
  CommentsState({
    this.postId,
    this.postMediaUrl,
    this.postOwnerId,
  });
  buildComments() {
    return StreamBuilder(
      stream: commentsRef
          .document(postId)
          .collection("comments")
          .orderBy("timestamp", descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<Comment> comments = [];
        snapshot.data.documents.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(
          children: comments,
        );
      },
    );
  }

  addComment() {
    commentsRef.document(postId).collection("comments").add({
      "username": currentUser.username,
      "userId": currentUser.id,
      "comment": commentController.text,
      "timestamp": timestamp,
      "avatarUrl": currentUser.photoURL,
    });
    bool isNotPostOwner = postOwnerId != currentUser.id;
    if (isNotPostOwner) {
      activityFeedRef.document(postOwnerId).collection('feedItems').add({
        "type": "comment",
        "commentData": commentController.text,
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoURL,
        "postId": postId,
        "mediaUrl": postMediaUrl,
        "timestamp": timestamp,
      });
    }

    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(
            child: buildComments(),
          ),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: "Write a Comment...",
              ),
            ),
            trailing: IconButton(
              onPressed: addComment,
              icon: Icon(
                Icons.send,
                size: 40.0,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;
  Comment({
    this.username,
    this.userId,
    this.avatarUrl,
    this.comment,
    this.timestamp,
  });
  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      avatarUrl: doc['avatarUrl'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      userId: doc['userId'],
      username: doc['username'],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          title: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: " $comment",
                    ),
                  ])),
          //Text("$username: $comment"),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
      ],
    );
  }
}
