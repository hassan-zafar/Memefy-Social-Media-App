import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;
  PostScreen({
    this.userId,
    this.postId,
  });
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: postRef
            .document(userId)
            .collection('userPosts')
            .document(postId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          Post post = Post.fromDocument(snapshot.data);
          return Center(
            child: Scaffold(
              appBar: header(context, titleText: post.description),
              body: ListView(
                children: <Widget>[
                  Container(
                    child: post,
                  )
                ],
              ),
            ),
          );
        });
  }
}
