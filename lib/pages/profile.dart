import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/post_state.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;
  final bool removeBackButton;

  Profile({this.profileId, this.removeBackButton = true});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currUserId = currUser?.id;
  String postView = "grid";
  int postCount = 0;
  List<Post> posts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    getProfilePosts();
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });

    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection("usersPosts")
        .orderBy("timestamp", descending: true)
        .getDocuments();

    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
                color: Colors.grey,
                fontSize: 15.0,
                fontWeight: FontWeight.w400),
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
          currentUserId: currUserId,
        ),
      ),
    );
  }

  FlatButton buildButton({String text, Function function}) {
    return FlatButton(
      padding: EdgeInsets.only(top: 2.0),
      onPressed: function,
      child: Container(
        width: 250.0,
        height: 27.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Theme.of(context).accentColor,
            border: Border.all(color: Theme.of(context).accentColor),
            borderRadius: BorderRadius.circular(5.0)),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  buildProfileButton() {
    bool isProfileOwner = widget.profileId == currUserId;

    if (isProfileOwner) {
      return buildButton(text: "Edit Profile", function: editProfile);
    }
    return Text("Profile Button");
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress(context);
        }

        User user = User.fromDocument(snapshot.data);

        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 40.0,
                        backgroundColor: Colors.grey,
                        backgroundImage:
                            CachedNetworkImageProvider(user.photoUrl),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text(
                          user.username,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          user.displayName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Text(user.bio),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", 0),
                            buildCountColumn("following", 0),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildProfileButton(),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress(context);
    } else if (posts.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(40.0),
              child: Text(
                "No Posts",
                style: TextStyle(
                  fontSize: 40.0,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postView == 'grid') {
      List<GridTile> gridTiles = [];

      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });

      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postView == 'list') {
      return Column(
        children: posts,
      );
    }
  }

  togglePostView(String postView) {
    if (this.postView == postView) return;

    setState(() {
      this.postView = postView;
    });
  }

  buildTogglePostsView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.grid_on),
          color:
              postView == 'grid' ? Theme.of(context).primaryColor : Colors.grey,
          onPressed: () => togglePostView('grid'),
        ),
        IconButton(
          icon: Icon(Icons.list),
          color:
              postView == 'list' ? Theme.of(context).primaryColor : Colors.grey,
          onPressed: () => togglePostView('list'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(
        context,
        titleText: "Profile",
        removeBackButton: widget.removeBackButton,
      ),
      body: ListView(
        children: [
          buildProfileHeader(),
          Divider(),
          buildTogglePostsView(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
  }
}

navigateToProfile(BuildContext context, {String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Profile(
        profileId: profileId,
        removeBackButton: false,
      ),
    ),
  );
}
