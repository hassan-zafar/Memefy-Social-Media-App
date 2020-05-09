import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:fluttershare/models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  Future<QuerySnapshot> searchResultsFuture;
  TextEditingController searchController = TextEditingController();
  handleSearch(String query) {
    Future<QuerySnapshot> users =
        userRef.where("username", isGreaterThanOrEqualTo: query).getDocuments();
    setState(() {
      searchResultsFuture = users;
    });
  }

  clearSearch() {
    searchController.clear();
  }

  Container buildNoContent() {
    Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: orientation == Orientation.portrait ? 350.0 : 180.0,
            ),
            Text(
              "Find Users",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  //fontWeight: FontWeight.w600,
                  //fontStyle: FontStyle.italic,
                  fontSize: orientation == Orientation.portrait ? 60.0 : 40.0,
                  fontFamily: 'Signatra',
                  wordSpacing: 10.0),
            )
          ],
        ),
      ),
    );
  }

  AppBar buildSearchField(context) {
    return AppBar(
      backgroundColor: Theme.of(context).accentColor,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
            hintText: "Search",
            filled: false,
            prefixIcon: Icon(Icons.search),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: clearSearch(),
            )),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  buildSearchResult() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          UserResult searchResult = UserResult(user);
          searchResults.add(searchResult);
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).accentColor,
      appBar: buildSearchField(context),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResult(),
    );
  }
}

showProfile(BuildContext context, {String profileId}) {
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Profile(
                profileId: profileId,
              )));
}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.photoURL),
                backgroundColor: Colors.grey,
              ),
              title: Text(
                user.displayname,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Divider(
            color: Colors.white54,
            thickness: 1.0,
            height: 2.0,
          )
        ],
      ),
    );
  }
}
