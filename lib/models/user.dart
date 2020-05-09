import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String bio;
  final String photoURL;
  final String displayname;
  final String email;

  User({
    this.id,
    this.username,
    this.email,
    this.bio,
    this.photoURL,
    this.displayname,
  });
  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc["id"],
      bio: doc["bio"],
      displayname: doc["displayname"],
      email: doc["email"],
      photoURL: doc["photoURL"],
      username: doc["username"],
    );
  }
}
