import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  Future<QuerySnapshot> searchResultsFuture;
  TextEditingController searchController = TextEditingController();

  handleSearch(String query) {
    Future<QuerySnapshot> res = usersRef
        .where("displayName", isGreaterThanOrEqualTo: query)
        .getDocuments();
    setState(() {
      this.searchResultsFuture = res;
    });
  }

  clearSearch() {
    searchController.clear();
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        onFieldSubmitted: handleSearch,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.account_box,
            size: 38.0,
          ),
          hintText: "Search for a user",
          filled: true,
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: clearSearch,
          ),
        ),
      ),
    );
  }

  Container buildNoContent() {
    Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              "assets/images/search.svg",
              height: orientation == Orientation.portrait ? 300.0 : 200.0,
            ),
            Text(
              "Find users",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 60.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  FutureBuilder buildSearchResults() {
    return FutureBuilder(
        future: searchResultsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress(context);
          }

          List<UserResult> searchResults = [];
          User user;

          snapshot.data.documents.forEach((doc) {
            user = User.fromDocument(doc);
            UserResult searchResult = UserResult(user);
            searchResults.add(searchResult);
          });

          return ListView(
            children: searchResults,
          );
        });
  }

  @override
  Scaffold build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: buildSearchField(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.withOpacity(0.7),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => navigateToProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }
}
