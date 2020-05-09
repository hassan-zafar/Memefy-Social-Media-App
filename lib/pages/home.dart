import 'dart:io';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/timeline.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/upload.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:fluttershare/models/user.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shimmer/shimmer.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final userRef = Firestore.instance.collection('users');
final activityFeedRef = Firestore.instance.collection('feed');
final postRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final DateTime timestamp = DateTime.now();
final StorageReference storageRef = FirebaseStorage.instance.ref();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool isAuth = false;
  bool showGoogleSignInButton = false;
  PageController pageController;
  int pageIndex = 0;
  @override
  void initState() {
    super.initState();
    pageController = PageController();
    //Detects when user
    //SignedIn
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      // print('User SignIn Error:$err');
    });
//ReAuthenticate User when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      // print('User SignIn Error:$err');
    });
  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getiOSPermission();

    _firebaseMessaging.getToken().then((token) {
      print("Firebase Messaging Token: $token\n");
      userRef.document(user.id).updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      // onLaunch: (Map<String, dynamic> message) async {},
      // onResume: (Map<String, dynamic> message) async {},
      onMessage: (Map<String, dynamic> message) async {
        print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          print("Notification shown!");
          SnackBar snackbar = SnackBar(
              content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print("Notification NOT shown");
      },
    );
  }

  getiOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings registered: $settings");
    });
  }

  createUserInFirestore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await userRef.document(user.id).get();
    if (!doc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      userRef.document(user.id).setData({
        "id": user.id,
        "username": username,
        "bio": "",
        "photoURL": user.photoUrl,
        "displayname": user.displayName,
        "timestamp": timestamp,
      });
      //make new users their own followers(to include their posts in their timeline)
      await followersRef
          .document(user.id)
          .collection('userFollowers')
          .document(user.id)
          .setData({});
      doc = await userRef.document(user.id).get();
    }
    currentUser = User.fromDocument(doc);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
    // print('Signed out!');
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 150),
      curve: Curves.easeInOut,
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),

      bottomNavigationBar: CurvedNavigationBar(
        color: Theme.of(context).primaryColor,
        //Theme.of(context).primaryColor,
        backgroundColor: Colors.white,
        buttonBackgroundColor: Theme.of(context).primaryColor,
        //Theme.of(context).primaryColor,
        height: 50,
        animationDuration: Duration(milliseconds: 600),
        index: pageIndex,
        onTap: onTap,
        items: <Widget>[
          Icon(
            Icons.whatshot,
            size: 35.0,
            color: Colors.white,
          ),
          Icon(
            Icons.notifications_none,
            size: 35.0,
            color: Colors.white,
          ),
          Icon(
            Icons.photo_camera,
            size: 35.0,
            color: Colors.white,
          ),
          Icon(
            Icons.search,
            size: 35.0,
            color: Colors.white,
          ),
          Icon(
            Icons.account_circle,
            size: 35.0,
            color: Colors.white,
          ),
        ],
      ),
//      bottomNavigationBar: CupertinoTabBar(
//        currentIndex: pageIndex,
//        onTap: onTap,
//        inactiveColor: Colors.white,
//        backgroundColor: Theme.of(context).accentColor,
//        activeColor: Theme.of(context).primaryColor,
//        items: [
//          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
//          BottomNavigationBarItem(icon: Icon(Icons.notifications_none)),
//          BottomNavigationBarItem(icon: Icon(Icons.photo_camera)),
//          BottomNavigationBarItem(icon: Icon(Icons.search)),
//          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
//        ],
//      ),
    );
//    return RaisedButton(
//      child: Text('Logout'),
//      onPressed: logout,
//    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        color: Theme.of(context).primaryColor,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Shimmer.fromColors(
              baseColor: Colors.black,
              highlightColor: Colors.white,
              child: Text(
                'MemeFy',
                style: TextStyle(
                  fontFamily: "Signatra",
                  fontSize: 90.0,
                  //color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260,
                height: 60,
                decoration: BoxDecoration(
                    image: DecorationImage(
                  image: AssetImage('assets/images/google_signin_button.png'),
                  fit: BoxFit.cover,
                )),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
