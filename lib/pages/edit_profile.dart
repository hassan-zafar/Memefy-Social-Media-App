import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserID;
  EditProfile({this.currentUserID});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioTextController = TextEditingController();
  User user;
  bool isLoading = false;
  bool _bioValid = true;
  bool _displayNameValid = true;
  bool _isUpdating = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await userRef.document(widget.currentUserID).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayname;
    bioTextController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            "Display Name",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: "Update Display Name",
            errorText: _displayNameValid ? null : "Name Too Short",
          ),
        ),
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            "Bio",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioTextController,
          decoration: InputDecoration(
            hintText: "Update Bio",
            errorText: _bioValid ? null : "Bio Too Long",
          ),
        ),
      ],
    );
  }

  logout() async {
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Home();
    }));
  }

  updateProfileData() {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;
      bioTextController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;
      _isUpdating = true;
    });
    if (_displayNameValid && _bioValid) {
      userRef.document(widget.currentUserID).updateData({
        "username": displayNameController.text,
        "bio": bioTextController.text
      });
      SnackBar snackbar = SnackBar(content: Text("Profile Updated"));
      _scaffoldKey.currentState.showSnackBar(snackbar);
      Timer(Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Edit Profile"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.done),
            onPressed: _isUpdating ? null : () => updateProfileData(),
          ),
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
                        child: CircleAvatar(
                          backgroundImage:
                              CachedNetworkImageProvider(user.photoURL),
                          radius: 60.0,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: <Widget>[
                            buildDisplayField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(25.0),
                        child: FlatButton.icon(
                          onPressed: () => logout(),
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 40,
                          ),
                          label: Text(
                            "Log Out",
                            style: TextStyle(color: Colors.red, fontSize: 20.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
